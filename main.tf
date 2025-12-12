terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.55.0"
    }
  }
}

# Provider Azure
provider "azurerm" {
  features {}

  subscription_id = "3c5a0c2b-a476-409a-88ee-9feb9f737fd8"
  tenant_id       = "7e0fbdf8-fad9-4463-adf6-e514553741a4"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.azure_location

  tags = {
    Project     = "devops-reto"
    Environment = var.environment
    Terraform   = "true"
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.aks_cluster_name}-dns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  sku_tier = "Free"

  tags = {
    Project     = "devops-reto"
    Environment = var.environment
    Terraform   = "true"
  }
}

# Outputs
output "resource_group_name" {
  description = "Nombre del RG donde se aprovisionó el AKS"
  value       = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  description = "Nombre del clúster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_get_credentials_command" {
  description = "Comando Azure CLI para obtener credenciales del cluster AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
}
