locals {
  namespace_name          = var.cluster_config.pipeline_name
  kafka_creds_secret_name = "${var.cluster_config.pipeline_name}-kafka-creds"
  connect_cluster_name    = "${var.cluster_config.pipeline_name}-cluster"
  service_account_name    = "${local.connect_cluster_name}-connect" # note the suffix is important, as the actual account name is created implicitly. automatically with that
  connect_deployment_name = "${local.connect_cluster_name}-connect"
  create_irsa_role        = var.cluster_config.connect_execution_role.role_name_to_create != null ? true : false
}

resource "kubectl_manifest" "namespace" {
  yaml_body = templatefile("${path.module}/templates/k8s/namespace.yaml", {
    name = local.namespace_name
  })
}

resource "kafka_user" "user" {
  project      = var.cluster_config.kafka_project_name
  service_name = var.cluster_config.kafka_service_name
  username     = "datalake-ingestor-${var.env}"
}

resource "kafka_acl" "user_acl" {
  for_each     = var.topic_permissions
  project      = var.cluster_config.kafka_project_name
  service_name = var.cluster_config.kafka_service_name
  username     = kafka_kafka_user.user.username
  topic        = each.key
  permission   = each.value
}

resource "kubectl_manifest" "kafka_connector" {
  count      = length(var.cluster_config.connectors)
  depends_on = [kubectl_manifest.kafka_connect]
  yaml_body = templatefile("${path.module}/templates/k8s/connector.yaml", {
    connector_name = replace(join("-", [
      var.cluster_config.pipeline_name, var.cluster_config.connectors[count.index].topic, "s3-sink-connector", var.stage
    ]), "_", "-")
    namespace                   = local.namespace_name
    connect_cluster_name        = local.connect_cluster_name
    topic                       = var.cluster_config.connectors[count.index].topic
    num_tasks                   = var.cluster_config.connectors[count.index].num_tasks
    bucket_name                 = var.cluster_config.bucket_name
    rotate_interval_ms          = var.cluster_config.connectors[count.index].rotate_interval_ms
    rotate_schedule_interval_ms = var.cluster_config.connectors[count.index].rotate_schedule_interval_ms
    partition_duration_ms       = var.cluster_config.connectors[count.index].partition_duration_ms
    data_category               = var.cluster_config.data_category
  })
  wait = true
}

resource "kubectl_manifest" "kafka_connect" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/connect.yaml", {
    stage                    = var.stage
    name                     = local.connect_cluster_name
    namespace                = local.namespace_name
    account_id               = data.aws_caller_identity.this.account_id
    region_name              = data.aws_region.this.name
    replicas                 = var.replicas
    kafka_connect_image_name = var.kafka_connect_image_name
    kafka_connect_image_tag  = var.kafka_connect_image_tag
    service_account_name     = local.service_account_name
    irsa_role_arn            = local.create_irsa_role ? module.irsa_role.iam_role_arn : var.cluster_config.connect_execution_role.existing_role_arn
    kafka_brokers            = var.cluster_config.kafka_brokers
    username                 = kafka_user.user.username
    secret_name              = local.kafka_creds_secret_name
  })
  wait = true
}

resource "kubectl_manifest" "kafka_secret" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/secret.yaml", {
    namespace     = local.namespace_name
    secret_name   = local.kafka_creds_secret_name
    kafka_user    = base64encode(kafka_user.user.username)
    kafka_pwd     = base64encode(kafka_user.user.password)
    kafka_ca_cert = base64encode(data.kafka_project.project.ca_cert)
    sasl          = base64encode("scram_sha256")
    tls           = base64encode("enable")
  })
}

resource "kubectl_manifest" "network_policy" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/network_policy.yaml", {
    namespace = local.namespace_name
  })
}

resource "kubectl_manifest" "keda_kafka_auth" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/keda_trigger_kafka_auth.yaml", {
    namespace   = local.namespace_name
    secret_name = local.kafka_creds_secret_name
  })
}

resource "kubectl_manifest" "keda_scaling" {
  count      = length(var.cluster_config.connectors)
  depends_on = [kubectl_manifest.kafka_connect]
  yaml_body = templatefile("${path.module}/templates/k8s/scaling.yaml", {
    namespace                = local.namespace_name
    kafka_connect_deployment = local.connect_deployment_name
    env                      = var.env
    kafka_brokers            = var.cluster_config.kafka_brokers
    kafka_topic              = var.cluster_config.connectors[count.index].topic
    kafka_lag_threshold      = var.cluster_config.connectors[count.index].kafka_lag_threshold
    kafka_consumer_group = replace(join("-", [
      var.cluster_config.pipeline_name, var.cluster_config.connectors[count.index].topic, "s3-sink-connector", var.stage
    ]), "_", "-")
  })
}

resource "kubectl_manifest" "metrics_config_map" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/metrics.yaml", {
    namespace = local.namespace_name
  })
}

resource "kubectl_manifest" "metrics_scarper" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body = templatefile("${path.module}/templates/k8s/metrics_scraper.yaml", {
    namespace = local.namespace_name
  })
}

module "irsa_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 4.0"
  role_name                     = var.cluster_config.connect_execution_role.role_name_to_create
  # Write here the name of the role you want to create
  create_role                   = local.create_irsa_role
  provider_url                  = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.namespace_name}:${local.service_account_name}"]
}
