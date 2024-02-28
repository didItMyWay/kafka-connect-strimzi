variable "team_name" {
  description = "Name of the Team using this project"
  type        = string
  default     = "B2C Offers"
}

variable "project" {
  description = "Project Name"
  type        = string
  default     = "offerlist-dl-ingestion"
}

variable "environment" {
  description = "AWS Environment for stage and prod"
  type        = string
  default     = "dev"
}

variable "eks_cluster_name" {
  type = string
}

variable "base_kubernetes_namespace" {
  default = "default"
  type    = string
}

variable "strimzi_image_tag" {
  type    = string
  default = "0.34.0"
}

variable "strimzi_kafka_operator_replicas" {
  type        = number
  default     = 0
  description = "Default replicas for the cluster operator"
}

variable "strimzi_kafka_operator_image_tag" {
  type        = string
  default     = "0.34.0"
  description = "Version for strimzi-kafka-operator - Check https://strimzi.io/blog/2018/11/01/using-helm/"
}

variable "strimzi_reconciliation_interval" {
  type = string
  default = "86400000"
  description = "Reconciliation interval in MS."
}

variable "strimzi_chart_name" {
  type        = string
  default     = "strimzi-kafka-operator"
  description = "Chart name to be installed"
}

variable "strimzi_repository_name" {
  type        = string
  default     = "https://strimzi.io/charts"
  description = "Repository URL where to locate the requested chart"
}

variable "strimzi_release_name" {
  type        = string
  default     = "strimzi"
  description = "Release name"
}

variable "kafka_connect_image_repo" {
  type = string
  default = "offerlist-kafka-connect"
  description = "AWS ECR Repository Name for Kafka Connect"
}

variable "kafka_connect_image_tag" {
  type        = string
  default     = "latest"
  description = "AWS ECR Image Tag for Kafka Connect"
}