provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      "omnistrate.com/managed-by" = "omnistrate"
    }
  }
}

terraform {
  required_providers {
    aws = {
      version = "~> 4.64.0"
    }
  }
}
