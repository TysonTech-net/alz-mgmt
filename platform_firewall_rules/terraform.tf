terraform {
  required_version = "~> 1.12"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.connectivity_subscription_id
  features {}
}

###############################################################################
# Remote State - Platform Shared (same pattern as workload stack)
###############################################################################

data "terraform_remote_state" "platform_shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.platform_shared_state.resource_group_name
    storage_account_name = var.platform_shared_state.storage_account_name
    container_name       = var.platform_shared_state.container_name
    key                  = var.platform_shared_state.key
    subscription_id      = var.platform_shared_state.subscription_id
    use_azuread_auth     = true
  }
}

###############################################################################
# Locals - Platform Shared Outputs
###############################################################################

locals {
  platform_shared_outputs = data.terraform_remote_state.platform_shared.outputs

  # Get firewall policies from platform_shared (keyed by hub key: "primary"/"secondary")
  firewall_policies = coalesce(
    try(local.platform_shared_outputs.hub_and_spoke_vnet_firewall_policies, null),
    {}
  )

  # Remap to region names using hub_region_mapping
  firewall_policy_ids = {
    for hub_key, region in var.hub_region_mapping : region => local.firewall_policies[hub_key].id
    if contains(keys(local.firewall_policies), hub_key)
  }
}
