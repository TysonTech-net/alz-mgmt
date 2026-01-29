terraform {
  required_version = "~> 1.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id = var.subscription_ids["security"]
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  alias                           = "connectivity"
  subscription_id                 = var.subscription_ids["connectivity"]
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
