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
  role_arn = aws_iam_role.example.arn

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
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.coder.name]
    command     = "aws"
  }
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
   name = "coder"
  }
}
