resource "azurerm_firewall_policy_rule_collection_group" "internet" {
  count = local.create_internet_group ? 1 : 0

  firewall_policy_id = var.firewall_policy_id
  name               = "${var.group_name_prefix}_Default_Internet_Rules"
  priority           = local.internet_settings.priority

  # ---------------- Azure management services - NETWORK rules ----------------
  dynamic "network_rule_collection" {
    for_each = local.internet_settings.enable_azure_services_network ? [1] : []

    content {
      name     = "AzureManagementServices_NetworkRules"
      priority = 101
      action   = "Allow"

      # AzureKMSWindowsActivation
      rule {
        name                  = "AzureKMSWindowsActivation"
        source_ip_groups      = local.internet_source_ip_groups
        destination_ports     = ["1688"]
        protocols             = ["TCP"]
        destination_addresses = ["23.102.135.246", "20.118.99.224", "40.83.235.53"]
      }

      # AzureMonitor (service tag)
      rule {
        name                  = "AzureMonitor"
        source_ip_groups      = local.internet_source_ip_groups
        destination_ports     = ["80", "443"]
        protocols             = ["Any"]
        destination_addresses = ["AzureMonitor"]
      }

      # AzureKeyVault (service tag)
      rule {
        name                  = "AzureKeyVault"
        source_ip_groups      = local.internet_source_ip_groups
        destination_ports     = ["443"]
        protocols             = ["Any"]
        destination_addresses = ["AzureKeyVault"]
      }

      # AzureSiteRecovery (service tag)
      rule {
        name                  = "AzureSiteRecovery"
        source_ip_groups      = local.internet_source_ip_groups
        destination_ports     = ["443", "9443"]
        protocols             = ["Any"]
        destination_addresses = ["AzureSiteRecovery"]
      }

      # Identity NTP – Identity NTS Rule (must be a NETWORK rule; UDP not allowed in app rules)
      rule {
        name                  = "Identity-NTS-Rule"
        source_ip_groups      = compact([local.ipg_identity_spokes])
        destination_ports     = ["123"]
        protocols             = ["UDP"]
        destination_addresses = ["*"]
      }
    }
  }

  # ---------------- Azure management services - APPLICATION rules ----------------
  dynamic "application_rule_collection" {
    for_each = local.internet_settings.enable_azure_services_app ? [1] : []

    content {
      name     = "AzureManagementServices_ApplicationRules"
      priority = 102
      action   = "Allow"

      # AzureBackup (FQDN tag)
      rule {
        name                  = "AzureBackup"
        source_ip_groups      = local.internet_source_ip_groups
        destination_fqdn_tags = ["AzureBackup"]

        protocols {
          port = 443
          type = "Https"
        }
      }

      # WindowsUpdate (FQDN tag)
      rule {
        name                  = "WindowsUpdate"
        source_ip_groups      = local.internet_source_ip_groups
        destination_fqdn_tags = ["WindowsUpdate"]

        protocols {
          port = 443
          type = "Https"
        }
      }

      # ServiceBus (wildcard FQDN)
      rule {
        name             = "ServiceBus"
        source_ip_groups = local.internet_source_ip_groups
        destination_fqdns = [
          "*.servicebus.windows.net",
        ]

        protocols {
          port = 443
          type = "Https"
        }
      }

      # WindowsDefender Cloud Protection
      rule {
        name             = "WindowsDefenderCloudProtection"
        source_ip_groups = local.internet_source_ip_groups
        destination_fqdns = [
          "wdcp.microsoft.com",
          "wdcpalt.microsoft.com",
        ]

        protocols {
          port = 443
          type = "Https"
        }
      }
    }
  }

  # ---------------- Datadog (optional) ----------------
  dynamic "network_rule_collection" {
    for_each = local.internet_settings.enable_datadog_network_rules ? [1] : []

    content {
      name     = "Datadog"
      priority = 104
      action   = "Allow"

      rule {
        name                  = "DatadogAgent_Agents"
        source_addresses      = ["*"]
        destination_addresses = ["34.107.172.23/32", "34.149.115.128/26", "35.190.30.199/32"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_Api"
        source_addresses      = ["*"]
        destination_addresses = ["34.107.236.155/32", "34.149.115.128/26", "35.241.2.229/32"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_Apm"
        source_addresses      = ["*"]
        destination_addresses = ["34.149.115.128/26", "35.190.78.95/32", "35.241.39.98/32"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_Global"
        source_addresses      = ["*"]
        destination_addresses = ["34.107.99.0/24"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name             = "DatadogAgent_Logs"
        source_addresses = ["*"]
        destination_addresses = [
          "34.107.147.46/32",
          "34.107.148.131/32",
          "34.117.189.27/32",
          "34.117.37.81/32",
          "34.120.15.173/32",
          "34.120.157.180/32",
          "34.120.31.75/32",
          "34.120.57.90/32",
          "34.120.77.189/32",
          "34.149.115.128/26",
          "34.95.101.191/32",
          "34.95.82.189/32",
          "34.96.71.221/32",
          "34.98.110.196/32",
          "34.98.83.239/32",
          "34.98.95.189/32",
          "35.186.255.142/32",
          "35.190.9.84/32",
          "35.227.218.104/32",
          "35.227.223.199/32",
          "35.241.40.151/32",
          "35.241.47.238/32",
          "35.241.8.156/32",
          "35.244.180.206/32",
          "35.244.200.248/32",
          "35.244.215.159/32",
          "35.244.221.148/32",
        ]
        destination_ports = ["443"]
        protocols         = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_Orchestrator"
        source_addresses      = ["*"]
        destination_addresses = ["34.149.115.128/26", "35.186.196.31/32"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_Process"
        source_addresses      = ["*"]
        destination_addresses = ["34.117.218.227/32", "34.149.115.128/26"]
        destination_ports     = ["443"]
        protocols             = ["TCP"]
      }

      rule {
        name                  = "DatadogAgent_NTP"
        source_addresses      = ["*"]
        destination_addresses = ["178.62.16.103", "193.62.22.82", "178.62.68.79", "94.154.96.7"]
        destination_ports     = ["123"]
        protocols             = ["UDP"]
      }
    }
  }

  # ---------------- LogicMonitor platform egress (optional) ----------------
  dynamic "network_rule_collection" {
    for_each = local.internet_settings.enable_logicmonitor_egress_rules ? [1] : []

    content {
      name     = "LogicMonitor"
      priority = 103
      action   = "Allow"

      rule {
        name             = "LogicMonitor_Platform"
        source_addresses = ["*"]
        destination_addresses = [
          "3.106.118.64/26",
          "18.139.118.192/26",
          "18.246.78.128/25",
          "34.223.95.64/26",
          "38.100.37.0/24",
          "38.134.126.0/24",
          "52.52.63.0/26",
          "52.202.255.64/26",
          "52.215.168.128/26",
          "54.193.15.255/32",
          "54.194.232.54/32",
          "54.209.7.170/32",
          "54.254.224.41/32",
          "69.25.43.0/24",
          "74.201.65.0/24",
          "149.5.93.0/24",
          "212.118.245.0/24",
        ]
        destination_ports = ["443"]
        protocols         = ["TCP"]
      }
    }
  }
}