terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

# Configure the IBM Provider
provider "ibm" {
}


variable "coder_version" {
  default = "0.13.6"
}

resource ibm_container_cluster "tfcluster" {
name            = "coder"
datacenter      = "dal10"
machine_type    = "b3c.4x16" # ibmcloud ks flavors --zone dal10
hardware        = "shared"

default_pool_size = 1
    
public_service_endpoint  = "true"
}


###############################################################
# K8s configuration
###############################################################
provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_foo.host
  client_certificate     = data.ibm_container_cluster_config.cluster_foo.admin_certificate
  client_key             = data.ibm_container_cluster_config.cluster_foo.admin_key
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_foo.ca_certificate
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder"
  }
}

###############################################################
# Coder configuration
###############################################################
# provider "helm" {
#   kubernetes {
#     host                   = digitalocean_kubernetes_cluster.coder.endpoint
#     token                  = digitalocean_kubernetes_cluster.coder.kube_config[0].token
#     cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.coder.kube_config[0].cluster_ca_certificate)
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
#     value = "coder"
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
#       value: "postgres://coder:coder@postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"
#     - name: CODER_EXPERIMENTAL
#       value: "true"
#     EOT
#   ]

#   depends_on = [
#     helm_release.pg_cluster
#   ]
# }