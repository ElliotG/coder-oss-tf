terraform {
  required_providers {
    linode = {
      source = "linode/linode"
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
# Set LINODE_TOKEN 
provider "linode" {}

resource "linode_lke_cluster" "coder" {
    label       = "coder"
    k8s_version = "1.24"
    region      = "us-central"
    tags        = ["prod"]

    pool {
        type  = "g6-standard-1"
        count = 1
    }
}

//Export this cluster's attributes
 resource "null_resource" "get_prometheus_ip" {
  provisioner "local-exec" {
    command = "echo ${linode_lke_cluster.coder.kubeconfig}"
  }
}

# provider "kubernetes" {
#   host                   = linode_lke_cluster.coder.kubeconfig.triggers.host
#   token                  = linode_lke_cluster.coder.kubeconfig.triggers.token
#   cluster_ca_certificate = base64decode(linode_lke_cluster.coder.kubeconfig.triggers.cluster_ca_certificate)
# }

# resource "kubernetes_namespace" "coder_namespace" {
#   metadata {
#     name = "coder"
#   }
# }

# # ###############################################################
# # # Coder configuration
# # ###############################################################
# provider "helm" {
#   kubernetes {
#     host                   = null_resource.kubeconfig.triggers.host
#     token                  = null_resource.kubeconfig.triggers.token
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
#     value = var.db_password
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