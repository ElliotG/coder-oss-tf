terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.3.0"
    }
  }
}

variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "coder_version" {
    default = "0.13.2"
}

provider "google" {
  region  = var.region
  project = var.project
}

###############################################################
# Set up the Networking Components
###############################################################
resource "google_compute_network" "vpc_network" {
  name                    = "gke-vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "k8s-network"
  ip_cidr_range = "10.3.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_container_cluster" "primary" {
  name     = "${var.project}-gke"
  location = var.region
  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.vpc_subnet.name
  enable_autopilot = true
  vertical_pod_autoscaling {
    enabled = true 
  }
}

###############################################################
# K8s configuration
###############################################################
data "google_client_config" "default" {
  depends_on = [google_container_cluster.primary]
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
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
    cluster_ca_certificate = base64decode(
      google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
    )
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
}
