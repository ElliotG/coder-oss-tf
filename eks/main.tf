terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "coder_version" {
    default = "0.12.7"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

###############################################################
# Set up the Networking Components
###############################################################
resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}


resource "aws_iam_role" "coder_eks_cluster_role" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "coder_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.coder_eks_cluster_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "coder_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.coder_eks_cluster_role.name
}

resource "aws_eks_cluster" "coder" {
  name     = "coder"
  role_arn = aws_iam_role.coder_eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.coder_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.coder_AmazonEKSVPCResourceController,
  ]
}

###############################################################
# K8s configuration
###############################################################
provider "kubernetes" {
  host                   = aws_eks_cluster.coder.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.coder.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.coder.name]
    command     = "aws"
  }
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
   name = "coder"
  }
}


###############################################################
# Helm configuration
###############################################################
provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(aws_eks_cluster.coder.certificate_authority[0].data)
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.coder.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.coder.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.coder.name]
      command     = "aws"
    }
  }
}


resource "helm_release" "pg_cluster" {
  name       = "postgresql"
  namespace  = kubernetes_namespace.coder_namespace.metadata.0.name
  
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  set {
    name  = "auth.username"
    value = "coder"
  }
  
  set {
    name  = "auth.password"
    value = "coder"
  } 
  
  set {
    name  = "auth.database"
    value = "coder"
  } 

  set {
    name  = "persistence.size"
    value = "10Gi"
  }  
}

resource "helm_release" "coder" {
  name       = "coder"
  namespace  = kubernetes_namespace.coder_namespace.metadata.0.name
  
  chart      = "https://github.com/coder/coder/releases/download/v${var.coder_version}/coder_helm_${var.coder_version}.tgz"

  values = [
    <<EOT
coder:
  env:
    - name: CODER_PG_CONNECTION_URL
      value: "postgres://coder:coder@postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"
    - name: CODER_AUTO_IMPORT_TEMPLATES
      value: "kubernetes"
    EOT
  ]

  depends_on = [
    helm_release.pg_cluster
  ]    
}
