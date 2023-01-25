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
  default = "0.13.6"
}

# Change this password away from the default if you are doing
# anything more than a testing stack.
variable "db_password" {
  default = "coder"
}


###############################################################
# Set up the Networking Components
###############################################################
# Set GOOGLE_CREDENTIALS
provider "google" {
  region  = var.region
  project = var.project
}

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

###############################################################
# K8s configuration
###############################################################
resource "google_container_cluster" "primary" {
  name                     = "${var.project}-gke"
  location                 = var.region
  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.vpc_subnet.name
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "coder_pool" {
  name     = "coder-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  node_config {
    machine_type = "e2-standard-2"
  }
}

data "google_client_config" "default" {
  depends_on = [google_container_cluster.primary, google_container_node_pool.coder_pool]
}

data "google_container_cluster" "primary" {
  name = google_container_cluster.primary.name
  zone = google_container_cluster.primary.location
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder"
  }
  depends_on = [google_container_cluster.primary, google_container_node_pool.coder_pool]
}

###############################################################
# Helm configuration
###############################################################
provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
          data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
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
    value = "${var.db_password}"
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
  env:
    - name: CODER_PG_CONNECTION_URL
      value: "postgres://coder:${var.db_password}@${helm_release.pg_cluster.name}.coder.svc.cluster.local:5432/coder?sslmode=disable"
    - name: CODER_EXPERIMENTAL
      value: "true"
    EOT
  ]

  depends_on = [
    helm_release.pg_cluster
  ]
}
