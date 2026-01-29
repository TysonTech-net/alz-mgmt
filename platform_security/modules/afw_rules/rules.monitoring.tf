resource "azurerm_firewall_policy_rule_collection_group" "monitoring" {
  count = local.create_monitoring_group ? 1 : 0

  firewall_policy_id = var.firewall_policy_id
  name               = "${var.group_name_prefix}_Default_Monitoring_Rules"
  priority           = local.monitoring_settings.priority

  # ---------------- General monitoring ----------------
  network_rule_collection {
    name     = "Monitoring_General_Monitoring"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "General - ICMP"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["*"]
      protocols             = ["ICMP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "General - Web"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["80", "443"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }
  }

  # ---------------- Windows monitoring ----------------
  network_rule_collection {
    name     = "Monitoring_Windows"
    priority = 110
    action   = "Allow"

    rule {
      name                  = "Windows Server - RPC Mapper"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["135"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "Windows Server - Server Message Block"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["445"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "Windows Server - WMI"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["24158"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "Windows Server - Active Directory"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["53", "88", "123", "389", "465", "3268", "3269", "49152-65535"]
      protocols             = ["TCP", "UDP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }
  }

  # ---------------- SQL monitoring ----------------
  network_rule_collection {
    name     = "Monitoring_SQL"
    priority = 120
    action   = "Allow"

    rule {
      name                  = "SQL Server Instance"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["1433", "1434"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }
  }

  # ---------------- Linux & network devices ----------------
  network_rule_collection {
    name     = "Monitoring_Linux_and_Network"
    priority = 130
    action   = "Allow"

    rule {
      name                  = "Linux and Network Devices - SNMP (UDP)"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["161"]
      protocols             = ["UDP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "Linux and Network Devices - SNMP (TCP)"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["10161"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }

    rule {
      name                  = "Linux and Network Devices - SSH"
      source_ip_groups      = [local.ipg_lm_collectors]
      destination_ports     = ["22"]
      protocols             = ["TCP"]
      destination_ip_groups = [local.ipg_lm_targets]
    }
  }
}