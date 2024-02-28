terraform {
  backend "s3" {
    bucket = "my-dev-bucket"
    key    = "ingestion/dev"
    region = "eu-central-1"
  }
  required_providers {
    aws   = "~> 5.0"
    aiven = {
      source  = "aiven/aiven"
      version = ">= 3.2.1"
    }

  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aiven" {
  api_token = data.aws_secretsmanager_secret_version.TokenValue.secret_string
}