locals {
  env = "dev"
}

variable "kafka_connect_image_tag" {
  description = "Image tag"
  default     = "latest"
}

module "strimzi_kafka_operator" {
  source = "../../module/kafka-connect-operator"

  eks_cluster_name                = "my-dev-cluster-for-deployment"
  strimzi_kafka_operator_replicas = 1
  kafka_connect_image_tag         = var.kafka_connect_image_tag
}

module "ingestion_pipeline" {
  source = "../../module/ingestion-pipeline"

  eks_cluster_name         = "my-dev-cluster-for-deployment"
  stage                    = local. env
  replicas                 = 1
  kafka_connect_image_name = "my-kafka-connect"
  kafka_connect_image_tag  = var.kafka_connect_image_tag

  topic_permissions = {
    "ingestion-connector-offsets-${local.env}" : "admin"
    "ingestion-connector-configs-${local.env}" : "admin"
    "ingestion-connector-status-${local.env}" : "admin"
    "my-input-data-topic" : "read"
  }

  cluster_config = {
    pipeline_name          = "development-ingestion"
    kafka_project_name     = "my-dev-kafka_project"
    kafka_service_name     = "my-dev-kafka_service"
    kafka_brokers          = "myhost:port"
    connect_execution_role = {
      role_name_to_create     = "connect-s3-sink-dev" 
    }
    bucket_name   = "my-dev-ingestion-bucket"
    data_category = "test"
    connectors    = [
      {
        topic                       = "my-input-data-topic"
        num_tasks                   = 4
        partition_duration_ms       = 3600000
        rotate_interval_ms          = 3600000
        rotate_schedule_interval_ms = 3600000
        kafka_lag_threshold         = "5000000"
      }
    ]
  }
}
