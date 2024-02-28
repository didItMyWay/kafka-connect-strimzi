data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_caller_identity" "this" {}

data "aws_region" "this" {}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}