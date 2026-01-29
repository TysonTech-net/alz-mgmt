locals {
  const = {
    connectivity = {
      virtual_wan        = "virtual_wan"
      hub_and_spoke_vnet = "hub_and_spoke_vnet"
      none               = "none"
    }
  }
}

# Build an implicit dependency on the resource groups
locals {
  resource_groups = {
  }
}

# Build policy dependencies
locals {
  management_group_dependencies = {
    policy_assignments = [
      module.management_resources,
    ]
    policy_role_assignments = [
      module.management_resources,
    ]
  }
}

locals {
  management_group_settings = merge(
    module.config.outputs.management_group_settings,
    {
      dependencies = local.management_group_dependencies
    }
  )
  management_resource_settings = merge(
    module.config.outputs.management_resource_settings,
    {
      tags = coalesce(module.config.outputs.management_resource_settings.tags, module.config.outputs.tags)
    }
  )
}


