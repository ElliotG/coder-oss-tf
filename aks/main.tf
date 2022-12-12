terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.3.0"
    }
  }
}

resource "azurerm_resource_group" "coder" {
  name     = "coder-resources"
  location = "Central US"
}