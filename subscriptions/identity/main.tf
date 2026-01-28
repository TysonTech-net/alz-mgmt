terraform {
  required_version = "~> 1.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = try(var.subscription_ids["identity"], var.subscription_id_identity)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias                           = "identity"
  resource_provider_registrations = "none"
  subscription_id                 = try(var.subscription_ids["identity"], var.subscription_id_identity)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias                           = "connectivity"
  resource_provider_registrations = "none"
  subscription_id                 = try(var.subscription_ids["connectivity"], var.subscription_id_connectivity)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias                           = "management"
  resource_provider_registrations = "none"
  subscription_id                 = try(var.subscription_ids["management"], var.subscription_id_management)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias                           = "security"
  resource_provider_registrations = "none"
  subscription_id                 = try(var.subscription_ids["security"], var.subscription_id_security)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["identity"], var.subscription_id_identity)
}

provider "azapi" {
  alias                      = "connectivity"
  skip_provider_registration = true
  subscription_id            = try(var.subscription_ids["connectivity"], var.subscription_id_connectivity)
}

module "identity_stack" {
  source = "../.."

  connectivity_type            = "none"
  management_resources_enabled = false
  management_groups_enabled    = false

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azurerm.management   = azurerm.management
    azurerm.security     = azurerm.security
    azapi                = azapi
    azapi.connectivity   = azapi.connectivity
  }
}
