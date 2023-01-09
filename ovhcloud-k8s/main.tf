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
  endpoint           = "ovh-us"
}

resource "ovh_cloud_project_kube" "mycluster" {
  name         = "coder_cluster"
  region       = "US-EAST-VA-1"
}

resource "local_file" "kubeconfig" {
  content     = ovh_cloud_project_kube.mycluster.kubeconfig
  filename = "config.yml"
}

# To authenticate with kubectl, use IBM Cloud Shell
# ~$ ibmcloud ks cluster config --cluster coder
# ~$ kubectl get pods -n coder
provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
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
#     host                   = data.ibm_container_cluster_config.coder.host
#     client_certificate     = data.ibm_container_cluster_config.coder.admin_certificate
#     client_key             = data.ibm_container_cluster_config.coder.admin_key
#     cluster_ca_certificate = data.ibm_container_cluster_config.coder.ca_certificate
#   }
# }

# # kubectl logs postgresql-0 -n coder
# resource "helm_release" "pg_cluster" {
#   name      = "postgresql"
#   namespace = kubernetes_namespace.coder_namespace.metadata.0.name

#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "postgresql"

#   # The default IBM storage class mounts the directory in as
#   # owned by nobody, causes Postgres to fail. Simplest fix is
#   # to use a different storage type.
#   # https://github.com/bitnami/charts/issues/4737
#   set {
#     name  = "primary.persistence.storageClass"
#     value = "ibmc-vpc-block-custom"
#   }    

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