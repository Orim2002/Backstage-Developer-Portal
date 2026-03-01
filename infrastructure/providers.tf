terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    bucket = "backstage-tfstate-orima"
    key = "backstage/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}