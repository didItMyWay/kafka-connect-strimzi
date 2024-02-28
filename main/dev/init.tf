terraform {
  backend "s3" {
    bucket = "my-dev-bucket"
    key    = "ingestion/dev"
    region = "eu-central-1"
  }
  required_providers {
    aws   = "~> 5.0"

  }
}

provider "aws" {
  region = "XXX"
}
