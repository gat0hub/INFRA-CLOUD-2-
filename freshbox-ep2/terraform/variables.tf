variable "region" {
  type    = string
  default = "us-east-1" # Learner Lab solo permite us-east-1 / us-west-2
}

variable "project" {
  type    = string
  default = "freshbox"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/22" # el enunciado pide un /22
}

variable "cluster_version" {
  type    = string
  default = "1.33" # verifica la versión disponible en tu consola EKS
}

variable "node_instance_type" {
  type    = string
  default = "t4g.small" # ARM64 (Graviton) -> imágenes Docker deben ser linux/arm64
}

variable "node_min" {
  type    = number
  default = 2
}

variable "node_max" {
  type    = number
  default = 4
}

# 3 nodos: con 10 pods de app + pods de sistema, 2 nodos t4g.small (~11 pods c/u) no alcanzan
variable "node_desired" {
  type    = number
  default = 3
}

# ALB -> frontend (80/443 según enunciado) y ALB -> backends (3001-3004 según la guía)
variable "pod_ports" {
  type    = list(number)
  default = [80, 443, 3001, 3002, 3003, 3004]
}

variable "db_username" {
  type    = string
  default = "alumno" # coincide con k8s/secret.yaml
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "" # déjalo vacío si init.sql ya hace CREATE DATABASE
}

variable "ecr_repositories" {
  type    = set(string)
  default = ["frontend", "get-products", "create-product", "update-product", "delete-product"]
}
