terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
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
# Networking configuration
###############################################################
# Set IC_API_KEY
provider "ibm" {
}

resource "ibm_is_vpc" "coder" {
  name = "codervpc"
}

resource "ibm_is_subnet" "coder" {
  name                     = "codersubnet"
  vpc                      = ibm_is_vpc.coder.id
  zone                     = "us-south-1"
  total_ipv4_address_count = 256
}

resource "ibm_is_public_gateway" "coder" {
  name = "coder-gateway"
  vpc  = ibm_is_vpc.coder.id
  zone = "us-south-1"
}

resource "ibm_is_subnet_public_gateway_attachment" "coder" {
  subnet                = ibm_is_subnet.coder.id
  public_gateway         = ibm_is_public_gateway.coder.id
}
###############################################################
# K8s configuration
###############################################################
# If the node gets stuck on waiting for the VPE Gateway, then
# open the cloud shell and run:
# ~$ ibmcloud ks cluster master refresh -c coder
resource "ibm_container_vpc_cluster" "coder" {
  name              = "coder"
  vpc_id            = ibm_is_vpc.coder.id
  flavor            = "bx2.4x16" # ibmcloud ks flavors --zone us-south-1
  worker_count      = 2

  zones {
    subnet_id = ibm_is_subnet.coder.id
    name      = ibm_is_subnet.coder.zone
  }

  depends_on = [
    ibm_is_subnet_public_gateway_attachment.coder
  ]
}

data "ibm_container_cluster_config" "coder" {
  cluster_name_id = ibm_container_vpc_cluster.coder.name
  admin           = true
}

# To authenticate with kubectl, use IBM Cloud Shell
# ~$ ibmcloud ks cluster config --cluster coder
# ~$ kubectl get pods -n coder
provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.coder.host
  client_certificate     = data.ibm_container_cluster_config.coder.admin_certificate
  client_key             = data.ibm_container_cluster_config.coder.admin_key
  cluster_ca_certificate = data.ibm_container_cluster_config.coder.ca_certificate
}

resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder"
  }
}

###############################################################
# Coder configuration
###############################################################
provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.coder.host
    client_certificate     = data.ibm_container_cluster_config.coder.admin_certificate
    client_key             = data.ibm_container_cluster_config.coder.admin_key
    cluster_ca_certificate = data.ibm_container_cluster_config.coder.ca_certificate
  }
}

# kubectl logs postgresql-0 -n coder
resource "helm_release" "pg_cluster" {
  name      = "postgresql"
  namespace = kubernetes_namespace.coder_namespace.metadata.0.name

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  # The default IBM storage class mounts the directory in as
  # owned by nobody, causes Postgres to fail. Simplest fix is
  # to use a different storage type.
  # https://github.com/bitnami/charts/issues/4737
  set {
    name  = "primary.persistence.storageClass"
    value = "ibmc-vpc-block-custom"
  }    

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