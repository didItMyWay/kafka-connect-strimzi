terraform {
  backend "s3" {
    bucket = "my-dev-bucket"
    key    = "ingestion/dev"
    region = "XXX"
  }
  required_providers {
    aws   = "~> 5.0"

  }
}

provider "aws" {
  region = "XXX"
}
