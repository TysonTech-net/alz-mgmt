terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription
}

provider "azapi" {
  subscription_id = var.subscription
}
