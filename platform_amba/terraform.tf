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
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    alz = {
      source  = "Azure/alz"
      version = "0.20.0"
    }
  }
  backend "azurerm" {}
}

provider "azapi" {
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["management"], data.azapi_client_config.current.subscription_id)
}

provider "azurerm" {
  alias           = "management"
  subscription_id = try(var.subscription_ids["management"], data.azapi_client_config.current.subscription_id)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}