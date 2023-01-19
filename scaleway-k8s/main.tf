terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
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
# Set DIGITALOCEAN_TOKEN
provider "scaleway" {}

resource "scaleway_k8s_cluster" "coder" {
  name    = "coder"
  version = "1.24.3"
  cni     = "cilium"
}

resource "scaleway_k8s_pool" "coder" {
  cluster_id = scaleway_k8s_cluster.coder.id
  name       = "coder"
  node_type  = "DEV1-M"
  size       = 1
}

resource "null_resource" "kubeconfig" {
  depends_on = [scaleway_k8s_pool.coder] # at least one pool here
  triggers = {
    host                   = scaleway_k8s_cluster.coder.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.coder.kubeconfig[0].token
    cluster_ca_certificate = scaleway_k8s_cluster.coder.kubeconfig[0].cluster_ca_certificate
  }
}

provider "kubernetes" {
  host  = null_resource.kubeconfig.triggers.host
  token = null_resource.kubeconfig.triggers.token
  cluster_ca_certificate = base64decode(null_resource.kubeconfig.triggers.cluster_ca_certificate)
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder"
  }
}

# ###############################################################
# # Coder configuration
# ###############################################################
# provider "helm" {
#   kubernetes {
#     host = null_resource.kubeconfig.triggers.host
#     token = null_resource.kubeconfig.triggers.token
#     cluster_ca_certificate = base64decode(null_resource.kubeconfig.triggers.cluster_ca_certificate)
#   }
# }

# resource "helm_release" "pg_cluster" {
#   name      = "postgresql"
#   namespace = kubernetes_namespace.coder_namespace.metadata.0.name

#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "postgresql"

#   set {
#     name  = "auth.username"
#     value = "coder"
#   }

#   set {
#     name  = "auth.password"
#     value = "${var.db_password}"
#   }

#   set {
#     name  = "auth.database"
#     value = "coder"
#   }

#   set {
#     name  = "persistence.size"
#     value = "10Gi"
#   }
# }

# resource "helm_release" "coder" {
#   name      = "coder"
#   namespace = kubernetes_namespace.coder_namespace.metadata.0.name

#   chart = "https://github.com/coder/coder/releases/download/v${var.coder_version}/coder_helm_${var.coder_version}.tgz"

#   values = [
#     <<EOT
# coder:
#   env:
#     - name: CODER_PG_CONNECTION_URL
#       value: "postgres://coder:${var.db_password}@${helm_release.pg_cluster.name}.coder.svc.cluster.local:5432/coder?sslmode=disable"
#     - name: CODER_EXPERIMENTAL
#       value: "true"
#     EOT
#   ]

#   depends_on = [
#     helm_release.pg_cluster
#   ]
# }