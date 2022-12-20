terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.3.0"
    }
  }
}

variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "coder_version" {
  default = "0.12.7"
}
# Multiple replicas is an enterprise feature:
# https://coder.com/trial
variable "coder_replicas" {
  type    = number
  default = 1
}
variable "enable_autopilot" {
  type    = bool
  default = true
}
# Set these if autopilot is disabled
variable "machine_type" {
  default = "e2-highmem-4"
}
variable "max_node_count" {
  type    = number
  default = 3
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
  name       = "${var.project}-gke"
  location   = var.region
  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.vpc_subnet.name

  vertical_pod_autoscaling {
    enabled = true
  }

  # Allow GKE to manage nodes on your behalf
  enable_autopilot = var.enable_autopilot
  # Otherwise, set up a node pool
  remove_default_node_pool = var.enable_autopilot ? null : true
  initial_node_count       = var.enable_autopilot ? null : 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {

  # Only create a seperate node pool if autopilot is disabled
  count = var.enable_autopilot ? 0 : 1

  name     = "coder-node-pool"
  location = "us-central1"
  cluster  = google_container_cluster.primary.name
  autoscaling {
    min_node_count = 1
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type = var.machine_type
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
  name      = "postgresql"
  namespace = kubernetes_namespace.coder_namespace.metadata.0.name

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
  name      = "coder"
  namespace = kubernetes_namespace.coder_namespace.metadata.0.name

  chart = "https://github.com/coder/coder/releases/download/v${var.coder_version}/coder_helm_${var.coder_version}.tgz"

  values = [
    <<EOT
coder:
  replicaCount: ${var.coder_replicas}
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
