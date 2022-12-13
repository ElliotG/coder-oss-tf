terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

variable "coder_version" {
    default = "0.12.7"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "coder" {
  name     = "coder-resources"
  location = "Central US"
}

#resource "azurerm_container_registry" "coder" {
#  name                = "coderregistry"
#  resource_group_name = azurerm_resource_group.coder.name
#  location            = azurerm_resource_group.coder.location
#  sku                 = "Basic"
#  admin_enabled       = false
#}

resource "azurerm_kubernetes_cluster" "coder" {
  name                = "coder-k8s-cluster"
  location            = azurerm_resource_group.coder.location
  resource_group_name = azurerm_resource_group.coder.name
  dns_prefix          = "coder-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "standard_d2ads_v5"
  }

  identity {
    type = "SystemAssigned"
  }
}

#resource "azurerm_role_assignment" "coder" {
#  principal_id                     = azurerm_kubernetes_cluster.coder.kubelet_identity[0].object_id
#  role_definition_name             = "AcrPull"
#  scope                            = azurerm_container_registry.coder.id
#  skip_service_principal_aad_check = true
#}

###############################################################
# K8s configuration
###############################################################
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.coder.kube_config.0.host
  username               = azurerm_kubernetes_cluster.coder.kube_config.0.username
  password               = azurerm_kubernetes_cluster.coder.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.cluster_ca_certificate)
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
    host                   = azurerm_kubernetes_cluster.coder.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.coder.kube_config.0.cluster_ca_certificate)
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

  depends_on = [
    helm_release.pg_cluster
  ]  
}