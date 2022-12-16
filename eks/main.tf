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
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "coder"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" : 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/coder" : "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "coder"
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 2
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}

###############################################################
# K8s configuration
###############################################################
data "aws_eks_cluster_auth" "cluster_auth" {
  name = "coder"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
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
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

resource "helm_release" "pg_cluster" {
  name       = "coder-db2"
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
  
  # chart      = "https://github.com/coder/coder/releases/download/v${var.coder_version}/coder_helm_${var.coder_version}.tgz"
  chart        = "./forked.tgz"

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

  set {
    name  = "service.sessionAffinity"
    value = "None"
  }
  set {
    name  = "coder.service.sessionAffinity"
    value = "None"
  }
  set {
    name = "coder.image.tag"
    value = "v0.0.1"
  }      

  depends_on = [
    helm_release.pg_cluster
  ]    
}
