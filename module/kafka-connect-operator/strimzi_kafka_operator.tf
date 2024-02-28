resource "helm_release" "strimzi" {
  name       = var.strimzi_release_name
  repository = var.strimzi_repository_name
  chart      = var.strimzi_chart_name
  version    = var.strimzi_image_tag
  namespace  = var.base_kubernetes_namespace
  verify     =  false
  values     = [
    templatefile("${path.module}/templates/k8s/strimzi_kafka_operator_values.yaml", {
      strimzi_kafka_operator_replicas  = var.strimzi_kafka_operator_replicas
      strimzi_kafka_operator_image_tag = var.strimzi_kafka_operator_image_tag
      strimzi_reconciliation_interval = jsonencode(var.strimzi_reconciliation_interval) # jsonencode to ensure the value is not converted to scientific notation(ex: 4.3ef)
      account_id                       = data.aws_caller_identity.this.account_id
      region_name                      = data.aws_region.this.name
      kafka_connect_image_repo         = var.kafka_connect_image_repo
      kafka_connect_image_tag          = var.kafka_connect_image_tag
    })
  ]
  depends_on = [kubectl_manifest.network_policy]
}