terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Bug fixes without moving to a new major version.
      version = "~> 5.60"
    }
  }
}
