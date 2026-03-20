# Providers

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # To create .zip lambda files
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

#Default provider
provider "aws" {
  region = var.aws_region
}

# CloudFront SSL certificates must live here
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# To keep the bucket names unique random suffix
resource "random_id" "suffix" {
  byte_length = 4
}