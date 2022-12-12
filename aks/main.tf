terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "coder" {
  name     = "coder-resources"
  location = "Central US"
}

resource "azurerm_container_registry" "coder" {
  name                = "coderregistry"
  resource_group_name = azurerm_resource_group.coder.name
  location            = azurerm_resource_group.coder.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "coder" {
  name                = "coder-k8s-cluster"
  location            = azurerm_resource_group.coder.location
  resource_group_name = azurerm_resource_group.coder.name
  dns_prefix          = "coder-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "coder" {
  principal_id                     = azurerm_kubernetes_cluster.coder.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.coder.id
  skip_service_principal_aad_check = true
}