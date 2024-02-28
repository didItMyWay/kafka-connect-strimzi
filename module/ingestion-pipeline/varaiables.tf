variable "env" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "replicas" {
  type = number
  description = "The number of replicas of connect cluster to be created"
  default = 0
}

variable "kafka_connect_image_name" {
  description = "The name of the Docker image for the Kafka Connect container"
  type        = string
  default     = "kafka-connect"
}

variable "kafka_connect_image_tag" {
  description = "The tag of the Docker image for the Kafka Connect container"
  type        = string
  default     = "dff9161"
}

variable "topic_permissions" {
  type        = map
  description = "key=topic_name ; value=permissions"
}

variable "cluster_config" {
  type = object({
    pipeline_name          = string
    kafka_project_name     = string
    kafka_service_name     = string
    kafka_brokers          = string
    # use either of the contained variables in-order to create new role or use existing one
    connect_execution_role = object({
      role_name_to_create = optional(string)
      existing_role_arn   = optional(string)
    })
    bucket_name   = string
    data_category = string
    connectors    = list(object({
      topic                       = string
      num_tasks                   = number
      partition_duration_ms       = number
      rotate_interval_ms          = number
      rotate_schedule_interval_ms = number
      kafka_lag_threshold         = string
    }))
  })
}