resource "azurerm_firewall_policy_rule_collection_group" "identity" {
  count = local.create_identity_group ? 1 : 0

  firewall_policy_id = var.firewall_policy_id
  name               = "${var.group_name_prefix}_Default_Identity_Rules"
  priority           = local.identity_settings.priority

  # ---------------- Outbound_DNS ----------------
  network_rule_collection {
    name     = "Outbound_DNS"
    priority = 101
    action   = "Allow"

    # Domain Controllers to Internet DNS - TCP
    rule {
      name                  = "Domain Controllers to Internet DNS - TCP"
      source_ip_groups      = [local.ipg_identity_spokes]
      destination_ports     = ["53"]
      protocols             = ["TCP"]
      destination_addresses = ["168.63.129.16"]
    }

    # Domain Controllers to Internet DNS - UDP
    rule {
      name                  = "Domain Controllers to Internet DNS - UDP"
      source_ip_groups      = [local.ipg_identity_spokes]
      destination_ports     = ["53"]
      protocols             = ["UDP"]
      destination_addresses = ["168.63.129.16"]
    }
  }

  # ---------------- Outbound_AzureADConnect ----------------
  network_rule_collection {
    name     = "Outbound_AzureADConnect"
    priority = 102
    action   = "Allow"

    # Domain Controllers - AzureActiveDirectory - TCP
    rule {
      name                  = "Domain Controllers - AzureActiveDirectory - TCP"
      source_ip_groups      = [local.ipg_identity_spokes]
      destination_ports     = ["443"]
      protocols             = ["TCP"]
      destination_addresses = ["AzureActiveDirectory"] # service tag
    }
  }

  # ---------------- Inbound_AzureBastion ----------------
  dynamic "network_rule_collection" {
    for_each = local.identity_settings.azure_bastion_subnet_prefix != null ? [1] : []

    content {
      name     = "Inbound_AzureBastion"
      priority = 103
      action   = "Allow"

      rule {
        name                  = "Azure Bastion to Identity VMs"
        source_addresses      = [local.identity_settings.azure_bastion_subnet_prefix]
        destination_ports     = ["3389", "22"]
        protocols             = ["TCP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }
    }
  }

  # ---------------- Inbound_ADDS_From_Spokes ----------------
  dynamic "network_rule_collection" {
    for_each = local.ipg_spokes != null ? [1] : []

    content {
      name     = "Inbound_ADDS_From_Spokes"
      priority = 104
      action   = "Allow"

      # ADDS Ports (TCP)
      rule {
        name                  = "ADDS Ports (TCP)"
        source_ip_groups      = [local.ipg_spokes]
        destination_ports     = ["135", "464", "49152-65535", "389", "636", "3268", "3269", "53", "88", "445", "9389"]
        protocols             = ["TCP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (UDP)
      rule {
        name                  = "ADDS Ports (UDP)"
        source_ip_groups      = [local.ipg_spokes]
        destination_ports     = ["123", "464", "389", "53", "88"]
        protocols             = ["UDP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (ICMP)
      rule {
        name                  = "ADDS Ports (ICMP)"
        source_ip_groups      = [local.ipg_spokes]
        destination_ports     = ["*"]
        protocols             = ["ICMP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }
    }
  }

  # ---------------- Inbound_ADDS_From_OutsideAzure ----------------
  dynamic "network_rule_collection" {
    for_each = local.ipg_onprem != null ? [1] : []

    content {
      name     = "Inbound_ADDS_From_OutsideAzure"
      priority = 105
      action   = "Allow"

      # ADDS Ports (TCP)
      rule {
        name                  = "ADDS Ports (TCP)"
        source_ip_groups      = [local.ipg_onprem]
        destination_ports     = ["135", "464", "49152-65535", "389", "636", "3268", "3269", "53", "88", "445", "9389"]
        protocols             = ["TCP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (UDP)
      rule {
        name                  = "ADDS Ports (UDP)"
        source_ip_groups      = [local.ipg_onprem]
        destination_ports     = ["123", "464", "389", "53", "88"]
        protocols             = ["UDP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (ICMP)
      rule {
        name                  = "ADDS Ports (ICMP)"
        source_ip_groups      = [local.ipg_onprem]
        destination_ports     = ["*"]
        protocols             = ["ICMP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }
    }
  }

  # ---------------- Bidirectional_ADDS_EvriDomainControllers ----------------
  dynamic "network_rule_collection" {
    for_each = local.ipg_domaincontrollers != null ? [1] : []

    content {
      name     = "Bidirectional_ADDS_EvriDomainControllers"
      priority = 106
      action   = "Allow"

      # ADDS Ports (TCP)
      rule {
        name                  = "ADDS Ports (TCP)"
        source_ip_groups      = [local.ipg_domaincontrollers]
        destination_ports     = ["135", "464", "49152-65535", "389", "636", "3268", "3269", "53", "88", "445", "9389"]
        protocols             = ["TCP"]
        destination_ip_groups = [local.ipg_domaincontrollers]
      }

      # ADDS Ports (UDP)
      rule {
        name                  = "ADDS Ports (UDP)"
        source_ip_groups      = [local.ipg_domaincontrollers]
        destination_ports     = ["123", "464", "389", "53", "88"]
        protocols             = ["UDP"]
        destination_ip_groups = [local.ipg_domaincontrollers]
      }

      # ADDS Ports (ICMP)
      rule {
        name                  = "ADDS Ports (ICMP)"
        source_ip_groups      = [local.ipg_domaincontrollers]
        destination_ports     = ["*"]
        protocols             = ["ICMP"]
        destination_ip_groups = [local.ipg_domaincontrollers]
      }
    }
  }

  # ---------------- Identity-To-Identity ----------------
  dynamic "network_rule_collection" {
    for_each = local.ipg_identity_spokes != null ? [1] : []

    content {
      name     = "Identity-To-Identity"
      priority = 107
      action   = "Allow"

      # ADDS Ports (TCP)
      rule {
        name                  = "ADDS Ports (TCP)"
        source_ip_groups      = [local.ipg_identity_spokes]
        destination_ports     = ["135", "464", "49152-65535", "389", "636", "3268", "3269", "53", "88", "445", "9389"]
        protocols             = ["TCP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (UDP)
      rule {
        name                  = "ADDS Ports (UDP)"
        source_ip_groups      = [local.ipg_identity_spokes]
        destination_ports     = ["123", "464", "389", "53", "88"]
        protocols             = ["UDP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }

      # ADDS Ports (ICMP)
      rule {
        name                  = "ADDS Ports (ICMP)"
        source_ip_groups      = [local.ipg_identity_spokes]
        destination_ports     = ["*"]
        protocols             = ["ICMP"]
        destination_ip_groups = [local.ipg_identity_spokes]
      }
    }
  }
}