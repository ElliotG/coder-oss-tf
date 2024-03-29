terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
    }
  }
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
# K8s configuration
###############################################################
# Set OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
# https://api.us.ovhcloud.com/createToken/?GET=/*&POST=/*&PUT=/*&DELETE=/*
# Set OVH_CLOUD_PROJECT_SERVICE to your Project ID
provider "ovh" {
  endpoint = "ovh-us"
}

resource "ovh_cloud_project_kube" "coder" {
  name   = "coder_cluster"
  region = "US-EAST-VA-1"
}


resource "ovh_cloud_project_kube_nodepool" "coder" {
  kube_id       = ovh_cloud_project_kube.coder.id
  name          = "coder-pool" //Warning: "_" char is not allowed!
  flavor_name   = "d2-8"
  desired_nodes = 2
  max_nodes     = 2
  min_nodes     = 2
}

provider "kubernetes" {
  host                   = yamldecode(ovh_cloud_project_kube.coder.kubeconfig).clusters[0].cluster.server
  token                  = yamldecode(ovh_cloud_project_kube.coder.kubeconfig).users[0].user.token
  cluster_ca_certificate = base64decode(yamldecode(ovh_cloud_project_kube.coder.kubeconfig).clusters[0].cluster.certificate-authority-data)

}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder"
  }

  depends_on = [
    ovh_cloud_project_kube_nodepool.coder
  ]
}

###############################################################
# Coder configuration
###############################################################
provider "helm" {
  kubernetes {
    host                   = yamldecode(ovh_cloud_project_kube.coder.kubeconfig).clusters[0].cluster.server
    token                  = yamldecode(ovh_cloud_project_kube.coder.kubeconfig).users[0].user.token
    cluster_ca_certificate = base64decode(yamldecode(ovh_cloud_project_kube.coder.kubeconfig).clusters[0].cluster.certificate-authority-data)
  }
}

# kubectl logs postgresql-0 -n coder
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
    value = var.db_password
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