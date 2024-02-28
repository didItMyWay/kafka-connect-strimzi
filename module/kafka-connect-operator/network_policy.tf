resource "kubectl_manifest" "network_policy" {
  yaml_body = templatefile("${path.module}/templates/k8s/network_policy.yaml", {
    base_kubernetes_namespace = var.base_kubernetes_namespace
  })
}