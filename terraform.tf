terraform {
  required_version = "~> 1.12"
  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "0.20.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  backend "azurerm" {}
}

provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

provider "azapi" {
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["management"], var.subscription_id_management)
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  alias                           = "management"
  subscription_id                 = try(var.subscription_ids["management"], var.subscription_id_management)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  alias                           = "connectivity"
  subscription_id                 = try(var.subscription_ids["connectivity"], var.subscription_id_connectivity)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  alias                      = "connectivity"
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["connectivity"], var.subscription_id_connectivity)
}

# Security subscription providers (for Sentinel and security LAW)
provider "azurerm" {
  resource_provider_registrations = "none"
  alias                           = "security"
  subscription_id                 = try(var.subscription_ids["security"], var.subscription_id_security)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  alias                      = "security"
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["security"], var.subscription_id_security)
}
