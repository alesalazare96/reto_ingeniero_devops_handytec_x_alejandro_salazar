variable "aws_region" {
  description = "Región de AWS donde se creará el clúster EKS"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS"
  type        = string
  default     = "devops-reto-eks"
}

variable "cluster_version" {
  description = "Versión de Kubernetes para EKS"
  type        = string
  default     = "1.30"
}

variable "environment" {
  description = "Etiqueta de entorno (dev, qa, prod, etc.)"
  type        = string
  default     = "dev"
}
