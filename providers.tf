provider "aws" {
  default_tags {
    tags = {
      Management = "Terraform"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}