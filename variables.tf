# variables.tf - Variables de entrada
# Nombre del Resource Group
variable "resource_group_name" {
  description = "Nombre del resource group para el cluster AKS"
  type        = string
  default     = "rg-devops-reto-aks"
}

# Región de Azure
variable "azure_location" {
  description = "Región de Azure donde se creará el resource group y AKS"
  type        = string
  default     = "eastus2"
}

# Nombre del cluster AKS
variable "aks_cluster_name" {
  description = "Nombre del cluster de AKS"
  type        = string
  default     = "devops-reto-aks"
}

# Prefijo DNS del cluster
variable "dns_prefix" {
  description = "Prefijo DNS para el cluster AKS"
  type        = string
  default     = "devopsreto"
}

# Entorno
variable "environment" {
  description = "Etiqueta de entorno (dev, qa, prod, etc.)"
  type        = string
  default     = "dev"
}

# Número de nodos del node pool
variable "node_count" {
  description = "Número de nodos en el node pool principal"
  type        = number
  default     = 1
}

# Tamaño de la VM para nodos
variable "node_vm_size" {
  description = "SKU de la VM a usar en los nodos del cluster"
  type        = string
  default     = "Standard_B2s"
}
