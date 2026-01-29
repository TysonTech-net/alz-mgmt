tags = {
  Description = "Management Resources"
  Service     = "Management"
  Environment = "Prod"
  CostCentre  = "Domain Integrations"
  Criticality = "Mission Critical"
  Owner       = "Infrastructure@hermesuk.onmicrosoft.com"
}

management_resource_settings = {
  enabled                                   = true
  location                                  = "$${starter_location_01}"
  log_analytics_workspace_name              = "$${log_analytics_workspace_name}"
  log_analytics_workspace_retention_in_days = 90 # EVRi requirement
  resource_group_name                       = "$${management_resource_group_name}"
  user_assigned_managed_identities = {
    ama = {
      name = "$${ama_user_assigned_managed_identity_name}"
    }
  }
  data_collection_rules = {
    change_tracking = { name = "$${dcr_change_tracking_name}" }
    defender_sql = {
      name    = "$${dcr_defender_sql_name}"
      enabled = false
    }
    vm_insights = { name = "$${dcr_vm_insights_name}" }
  }
  log_analytics_solution_plans = [
    { product = "OMSGallery/ContainerInsights" },
    { product = "OMSGallery/VMInsights" },
    { product = "OMSGallery/AgentHealthAssessment" },
    { product = "OMSGallery/AntiMalware" },
    { product = "OMSGallery/ChangeTracking" },
    { product = "OMSGallery/ServiceMap" },
    { product = "OMSGallery/SQLAssessment" },
    { product = "OMSGallery/SQLVulnerabilityAssessment" },
    { product = "OMSGallery/SQLAdvancedThreatProtection" }
  ]
}

management_group_settings = {
  enabled            = true
  architecture_name  = "alz_custom"
  location           = "$${starter_location_01}"
  parent_resource_id = "$${root_parent_management_group_id}"
  policy_default_values = {
    ama_change_tracking_data_collection_rule_id = "$${ama_change_tracking_data_collection_rule_id}"
    ama_mdfc_sql_data_collection_rule_id        = "$${ama_mdfc_sql_data_collection_rule_id}"
    ama_vm_insights_data_collection_rule_id     = "$${ama_vm_insights_data_collection_rule_id}"
    ama_user_assigned_managed_identity_id       = "$${ama_user_assigned_managed_identity_id}"
    ama_user_assigned_managed_identity_name     = "$${ama_user_assigned_managed_identity_name}"
    log_analytics_workspace_id                  = "$${log_analytics_workspace_id}"
    ddos_protection_plan_id                     = "$${ddos_protection_plan_id}"
    private_dns_zone_subscription_id            = "$${subscription_id_connectivity}"
    private_dns_zone_region                     = "$${starter_location_01}"
    private_dns_zone_resource_group_name        = "$${dns_resource_group_name}"
  }
  subscription_placement = {
    evri-identity = {
      subscription_id       = "$${subscription_id_identity}"
      management_group_name = "evri-identity"
    }
    evri-connectivity = {
      subscription_id       = "$${subscription_id_connectivity}"
      management_group_name = "evri-connectivity"
    }
    evri-management = {
      subscription_id       = "$${subscription_id_management}"
      management_group_name = "evri-management"
    }
    evri-security = {
      subscription_id       = "$${subscription_id_security}"
      management_group_name = "evri-security"
    }
    evri-sandbox = {
      subscription_id       = "2acb14a9-0da2-433e-8c34-74bf037f7de3"
      management_group_name = "evri-sandbox"
    }
  }
  policy_assignments_to_modify = {
    "evri" = {
      policy_assignments = {
        # ALZ inbuilt policies -------------------------------------------------
        "Audit-ResourceRGLocation" = { enforcement_mode = "Default" }      # Resource Group and Resource locations should match
        "Audit-TrustedLaunch"      = { enforcement_mode = "Default" }      # Audit virtual machines for Trusted Launch support
        "Audit-UnusedResources"    = { enforcement_mode = "Default" }      # Unused resources driving cost should be avoided
        "Audit-ZoneResiliency"     = { enforcement_mode = "Default" }      # Resources should be Zone Resilient
        "Deny-Classic-Resources"   = { enforcement_mode = "Default" }      # Deny the deployment of classic resources
        "Deny-UnmanagedDisk"       = { enforcement_mode = "Default" }      # Deny virtual machines and virtual machine scale sets that do not use managed disk
        "Deploy-AzActivity-Log"    = { enforcement_mode = "Default" }      # Configure Azure Activity logs to stream to specified Log Analytics workspace
        "Deploy-Diag-LogsCat"      = { enforcement_mode = "Default" }      # Enable category group resource logging for supported resources to Log Analytics
        "Deploy-ASC-Monitoring"    = { enforcement_mode = "Default" }      # Microsoft Cloud Security Benchmark
        "Deploy-MDEndpoints"       = { enforcement_mode = "DoNotEnforce" } # [Preview]: Deploy Microsoft Defender for Endpoint agent
        "Deploy-MDEndpointsAMA"    = { enforcement_mode = "DoNotEnforce" } # Configure multiple Microsoft Defender for Endpoint integration settings with Microsoft Defender for Cloud

        "Deploy-MDFC-Config-H224" = {
          enforcement_mode = "DoNotEnforce"
          parameters = {
            ascExportResourceGroupName                  = "$${asc_export_resource_group_name}"
            ascExportResourceGroupLocation              = "$${starter_location_01}"
            createResourceGroup                         = false
            emailSecurityContact                        = "$${defender_email_security_contact}"
            enableAscForServers                         = "Disabled"
            enableAscForServersVulnerabilityAssessments = "Disabled"
            enableAscForSql                             = "Disabled"
            enableAscForAppServices                     = "Disabled"
            enableAscForStorage                         = "Disabled"
            enableAscForContainers                      = "Disabled"
            enableAscForKeyVault                        = "Disabled"
            enableAscForSqlOnVm                         = "Disabled"
            enableAscForArm                             = "Disabled"
            enableAscForOssDb                           = "Disabled"
            enableAscForCosmosDbs                       = "Disabled"
            enableAscForCspm                            = "Disabled"
          }
        } # Deploy Microsoft Defender for Cloud configuration

        "Deploy-MDFC-OssDb"  = { enforcement_mode = "DoNotEnforce" } # Configure Advanced Threat Protection to be enabled on open-source relational databases
        "Deploy-MDFC-SqlAtp" = { enforcement_mode = "DoNotEnforce" } # Configure Azure Defender to be enabled on SQL Servers and SQL Managed Instances
        "Deploy-SvcHealth-BuiltIn" = {
          parameters = {
            alertRuleName         = "Alert-ServiceHealth"
            resourceGroupName     = "rg-subscription-azure-monitor-alerts-001"
            resourceGroupLocation = "$${starter_location_01}"
            createNewActionGroup  = "false"
            actionGroups = [
              "/subscriptions/$${subscription_id_management}/resourceGroups/$${scc_custom_management_resource_group_name}/providers/Microsoft.Insights/actionGroups/Ops-Action-Group-ServiceHealth"
            ]
            additionalTags = {
              Description = "Azure Monitor alerts for the subscription"
              Service     = "Azure-Monitor-Alerts"
              Environment = "Production"
              CostCentre  = "Domain Integrations"
              Criticality = "Mission Critical"
              Owner       = "Infrastructure@hermesuk.onmicrosoft.com"
              DeployedBy  = "Azure_Policy"
            }
          }
        }                                                      # Configure subscriptions to enable service health alert monitoring rule
        "Enforce-ACSB" = { enforcement_mode = "DoNotEnforce" } # Enforce Azure Compute Security Baseline compliance auditing

        # SCC additional policy assignments ------------------------------------
        "PA-Evri-Tagging-Baseline" = {
          parameters = {
            patchGroupTagValues = [
              "NonCritical-Monthly-Every2ndTuesday-Offset-2days-2200hrs",
              "Critical-Monthly-Every2ndTuesday-Offset-4days-2200hrs",
              "Critical-Monthly-HA-Every2ndTuesday-Offset-11days-2200hrs",
              "None",
              "N/A"
            ],
            backupTagValues = [
              "Yes",
              "No"
            ],
            excludedResourceTypes = [
              "microsoft.compute/virtualmachines/extensions",
              "microsoft.network/networkwatchers",
              "microsoft.compute/restorepointcollections",
              "microsoft.compute/restorepointcollections/restorepoints",
              "microsoft.compute/snapshots",
            ]
          }
          enforcement_mode = "Default"
        }
        "PA-Evri-Compute-Baseline" = {
          enforcement_mode = "Default",
          parameters = {
            approvedExtensions = [
              # General / config
              "CustomScriptExtension", # Windows
              "CustomScript",          # Linux
              "BGInfo",
              "VMAccessAgent", # Windows
              "VMAccessForLinux",

              # Microsoft Entra (AAD) login
              "AADLoginForWindows",
              "AADSSHLoginForLinux",

              # Azure Monitor & insights
              "AzureMonitorWindowsAgent",
              "AzureMonitorLinuxAgent",
              "DependencyAgentWindows",
              "DependencyAgentLinux",

              # Network Watcher
              "NetworkWatcherAgentWindows",
              "NetworkWatcherAgentLinux",

              # OS update (Update Manager)
              "WindowsOsUpdateExtension",
              "LinuxOsUpdateExtension",

              # Key Vault cert auto-rotation
              "KeyVaultForWindows",
              "KeyVaultForLinux",

              # Disk encryption
              "AzureDiskEncryption",         # Windows (BitLocker)
              "AzureDiskEncryptionForLinux", # Linux (dm-crypt)

              # Azure Backup (BAREs)
              "VMSnapshot",                 # Windows VM backup snapshot
              "VMSnapshotLinux",            # Linux VM backup snapshot
              "AzureBackupWindowsWorkload", # Workload backup (e.g., SQL)
              "AzureBackupLinuxWorkload",   # Workload backup on Linux (e.g., HANA)

              # Defender for Endpoint
              "MDE.Windows",
              "MDE.Linux",

              # Hybrid Runbook Worker (Automation)
              "HybridWorkerForWindows",
              "HybridWorkerForLinux",

              # Windows Admin Center in Azure
              "AdminCenter",

              # Guest configuration / policy inside the VM
              "AzurePolicyforWindows", # (aka Machine/Guest Configuration extension)
              "AzurePolicyforLinux",

              # Boot integrity (Trusted Launch / Confidential VM attestation)
              "GuestAttestation",

              # SQL IaaS extension (classic VM extension surface)
              "SqlIaasExtension"
            ]
          }
        },
        "AllLogs-To-Rapid7-EH" = {
          enforcement_mode = "Default"
          parameters = {
            resourceLocation            = "$${starter_location_01}"
            eventHubAuthorizationRuleId = "/subscriptions/$${subscription_id_security}/resourceGroups/rg-shared-security-prod-uks-rapid7-001/providers/Microsoft.EventHub/namespaces/evh-ns-evri-rapid7-prod-uks-001/authorizationRules/AzPlatformLogs-Send"
            eventHubName                = "evh-evri-rapid7-prod-uks-001"
            resourceTypeList = [
              "microsoft.network/azurefirewalls",
              "microsoft.network/applicationgateways",
              "microsoft.network/frontdoors",
              "microsoft.network/networksecuritygroups",
              "microsoft.network/virtualnetworkgateways",
              "microsoft.network/virtualnetworks",
              "microsoft.network/vpngateways",
              "microsoft.keyvault/vaults",
              "microsoft.keyvault/managedhsms",
              "microsoft.eventhub/namespaces",
              "microsoft.servicebus/namespaces",
              "microsoft.operationalinsights/workspaces",
              "microsoft.sql/managedinstances",
              "microsoft.sql/managedinstances/databases",
              "microsoft.sql/servers/databases",
              "microsoft.synapse/workspaces",
              "microsoft.network/bastionhosts",
              "microsoft.network/dnsresolverpolicies",
              "microsoft.network/networkmanagers",
              "microsoft.network/trafficmanagerprofiles",
              "microsoft.recoveryservices/vaults",
              "microsoft.network/expressroutecircuits",
              "microsoft.network/p2svpngateways",
              "microsoft.network/publicipaddresses",
              "microsoft.network/publicipprefixes",
              "microsoft.network/loadbalancers"
            ]
            diagnosticSettingName = "setByPolicy-Rapid7-EventHub"
          }
        },
        "ActivityLog-To-Rapid7-EH" = {
          enforcement_mode = "Default"
          parameters = {
            eventHubRuleId = "/subscriptions/$${subscription_id_security}/resourceGroups/rg-shared-security-prod-uks-rapid7-001/providers/Microsoft.EventHub/namespaces/evh-ns-evri-rapid7-prod-uks-001/authorizationRules/AzPlatformLogs-Send"
            eventHubName   = "evh-evri-rapid7-prod-uks-001"
            profileName    = "ActivityLog-To-Rapid7"
            logsEnabled    = "True"
            profileName    = "setByPolicy-Rapid7-EventHub"
          }
        }
        "Audit-Logs-To-Rapid7-EH" = {
          enforcement_mode = "Default"
          parameters = {
            resourceLocation            = "$${starter_location_01}"
            eventHubAuthorizationRuleId = "/subscriptions/$${subscription_id_security}/resourceGroups/rg-shared-security-prod-uks-rapid7-001/providers/Microsoft.EventHub/namespaces/evh-ns-evri-rapid7-prod-uks-001/authorizationRules/AzPlatformLogs-Send"
            eventHubName                = "evh-evri-rapid7-prod-uks-001"
            diagnosticSettingName       = "setByPolicy-Rapid7-EventHub"
          }
        }
        "PA-Evri-General-Baseline" = {
          parameters = {
            listOfAllowedLocations = [
              "UK South",
              "UK West",
              "West Europe"
            ]
            listOfAllowedSKUs = [
              "Basic_A0",
              "Basic_A1",
              "Basic_A2",
              "Basic_A3",
              "Basic_A4",
              "Standard_A0",
              "Standard_A1",
              "Standard_A10",
              "Standard_A11",
              "Standard_A1_v2",
              "Standard_A2",
              "Standard_A2_v2",
              "Standard_A2m_v2",
              "Standard_A3",
              "Standard_A4",
              "Standard_A4_v2",
              "Standard_A4m_v2",
              "Standard_A5",
              "Standard_A6",
              "Standard_A7",
              "Standard_A8",
              "Standard_A8_v2",
              "Standard_A8m_v2",
              "Standard_A9",
              "Standard_B12ms",
              "Standard_B16als_v2",
              "Standard_B16as_v2",
              "Standard_B16ls_v2",
              "Standard_B16ms",
              "Standard_B16pls_v2",
              "Standard_B16ps_v2",
              "Standard_B16s_v2",
              "Standard_B1ls",
              "Standard_B1ms",
              "Standard_B1s",
              "Standard_B20ms",
              "Standard_B2als_v2",
              "Standard_B2as_v2",
              "Standard_B2ats_v2",
              "Standard_B2ls_v2",
              "Standard_B2ms",
              "Standard_B2pls_v2",
              "Standard_B2ps_v2",
              "Standard_B2pts_v2",
              "Standard_B2s",
              "Standard_B2s_v2",
              "Standard_B2ts_v2",
              "Standard_B32als_v2",
              "Standard_B32as_v2",
              "Standard_B32ls_v2",
              "Standard_B32s_v2",
              "Standard_B4als_v2",
              "Standard_B4as_v2",
              "Standard_B4ls_v2",
              "Standard_B4ms",
              "Standard_B4pls_v2",
              "Standard_B4ps_v2",
              "Standard_B4s_v2",
              "Standard_B8als_v2",
              "Standard_B8as_v2",
              "Standard_B8ls_v2",
              "Standard_B8ms",
              "Standard_B8pls_v2",
              "Standard_B8ps_v2",
              "Standard_B8s_v2",
              "Standard_D1",
              "Standard_D11",
              "Standard_D11_v2",
              "Standard_D11_v2_Promo",
              "Standard_D12",
              "Standard_D128ds_v6",
              "Standard_D128lds_v6",
              "Standard_D128ls_v6",
              "Standard_D128s_v6",
              "Standard_D12_v2",
              "Standard_D12_v2_Promo",
              "Standard_D13",
              "Standard_D13_v2",
              "Standard_D13_v2_Promo",
              "Standard_D14",
              "Standard_D14_v2",
              "Standard_D14_v2_Promo",
              "Standard_D15_v2",
              "Standard_D16_v3",
              "Standard_D16_v4",
              "Standard_D16_v5",
              "Standard_D16a_v4",
              "Standard_D16ads_v5",
              "Standard_D16ads_v6",
              "Standard_D16alds_v6",
              "Standard_D16als_v6",
              "Standard_D16as_v4",
              "Standard_D16as_v5",
              "Standard_D16as_v6",
              "Standard_D16d_v4",
              "Standard_D16d_v5",
              "Standard_D16ds_v4",
              "Standard_D16ds_v5",
              "Standard_D16ds_v6",
              "Standard_D16lds_v5",
              "Standard_D16lds_v6",
              "Standard_D16ls_v5",
              "Standard_D16ls_v6",
              "Standard_D16pds_v5",
              "Standard_D16pds_v6",
              "Standard_D16plds_v5",
              "Standard_D16plds_v6",
              "Standard_D16pls_v5",
              "Standard_D16pls_v6",
              "Standard_D16ps_v5",
              "Standard_D16ps_v6",
              "Standard_D16s_v3",
              "Standard_D16s_v4",
              "Standard_D16s_v5",
              "Standard_D16s_v6",
              "Standard_D192ds_v6",
              "Standard_D192s_v6",
              "Standard_D1_v2",
              "Standard_D2",
              "Standard_D2_v2",
              "Standard_D2_v2_Promo",
              "Standard_D2_v3",
              "Standard_D2_v4",
              "Standard_D2_v5",
              "Standard_D2a_v4",
              "Standard_D2ads_v5",
              "Standard_D2ads_v6",
              "Standard_D2alds_v6",
              "Standard_D2als_v6",
              "Standard_D2as_v4",
              "Standard_D2as_v5",
              "Standard_D2as_v6",
              "Standard_D2d_v4",
              "Standard_D2d_v5",
              "Standard_D2ds_v4",
              "Standard_D2ds_v5",
              "Standard_D2ds_v6",
              "Standard_D2lds_v5",
              "Standard_D2lds_v6",
              "Standard_D2ls_v5",
              "Standard_D2ls_v6",
              "Standard_D2pds_v5",
              "Standard_D2pds_v6",
              "Standard_D2plds_v5",
              "Standard_D2plds_v6",
              "Standard_D2pls_v5",
              "Standard_D2pls_v6",
              "Standard_D2ps_v5",
              "Standard_D2ps_v6",
              "Standard_D2s_v3",
              "Standard_D2s_v4",
              "Standard_D2s_v5",
              "Standard_D2s_v6",
              "Standard_D3",
              "Standard_D32_v3",
              "Standard_D32_v4",
              "Standard_D32_v5",
              "Standard_D32a_v4",
              "Standard_D32ads_v5",
              "Standard_D32ads_v6",
              "Standard_D32alds_v6",
              "Standard_D32als_v6",
              "Standard_D32as_v4",
              "Standard_D32as_v5",
              "Standard_D32as_v6",
              "Standard_D32d_v4",
              "Standard_D32d_v5",
              "Standard_D32ds_v4",
              "Standard_D32ds_v5",
              "Standard_D32ds_v6",
              "Standard_D32lds_v5",
              "Standard_D32lds_v6",
              "Standard_D32ls_v5",
              "Standard_D32ls_v6",
              "Standard_D32pds_v5",
              "Standard_D32pds_v6",
              "Standard_D32plds_v5",
              "Standard_D32plds_v6",
              "Standard_D32pls_v5",
              "Standard_D32pls_v6",
              "Standard_D32ps_v5",
              "Standard_D32ps_v6",
              "Standard_D32s_v3",
              "Standard_D32s_v4",
              "Standard_D32s_v5",
              "Standard_D32s_v6",
              "Standard_D3_v2",
              "Standard_D3_v2_Promo",
              "Standard_D4",
              "Standard_D48_v3",
              "Standard_D48_v4",
              "Standard_D48_v5",
              "Standard_D48a_v4",
              "Standard_D48ads_v5",
              "Standard_D48ads_v6",
              "Standard_D48alds_v6",
              "Standard_D48als_v6",
              "Standard_D48as_v4",
              "Standard_D48as_v5",
              "Standard_D48as_v6",
              "Standard_D48d_v4",
              "Standard_D48d_v5",
              "Standard_D48ds_v4",
              "Standard_D48ds_v5",
              "Standard_D48ds_v6",
              "Standard_D48lds_v5",
              "Standard_D48lds_v6",
              "Standard_D48ls_v5",
              "Standard_D48ls_v6",
              "Standard_D48pds_v5",
              "Standard_D48pds_v6",
              "Standard_D48plds_v5",
              "Standard_D48plds_v6",
              "Standard_D48pls_v5",
              "Standard_D48pls_v6",
              "Standard_D48ps_v5",
              "Standard_D48ps_v6",
              "Standard_D48s_v3",
              "Standard_D48s_v4",
              "Standard_D48s_v5",
              "Standard_D48s_v6",
              "Standard_D4_v2",
              "Standard_D4_v2_Promo",
              "Standard_D4_v3",
              "Standard_D4_v4",
              "Standard_D4_v5",
              "Standard_D4a_v4",
              "Standard_D4ads_v5",
              "Standard_D4ads_v6",
              "Standard_D4alds_v6",
              "Standard_D4als_v6",
              "Standard_D4as_v4",
              "Standard_D4as_v5",
              "Standard_D4as_v6",
              "Standard_D4d_v4",
              "Standard_D4d_v5",
              "Standard_D4ds_v4",
              "Standard_D4ds_v5",
              "Standard_D4ds_v6",
              "Standard_D4lds_v5",
              "Standard_D4lds_v6",
              "Standard_D4ls_v5",
              "Standard_D4ls_v6",
              "Standard_D4pds_v5",
              "Standard_D4pds_v6",
              "Standard_D4plds_v5",
              "Standard_D4plds_v6",
              "Standard_D4pls_v5",
              "Standard_D4pls_v6",
              "Standard_D4ps_v5",
              "Standard_D4ps_v6",
              "Standard_D4s_v3",
              "Standard_D4s_v4",
              "Standard_D4s_v5",
              "Standard_D4s_v6",
              "Standard_D5_v2",
              "Standard_D5_v2_Promo",
              "Standard_D64_v3",
              "Standard_D64_v4",
              "Standard_D64_v5",
              "Standard_D64a_v4",
              "Standard_D64ads_v5",
              "Standard_D64ads_v6",
              "Standard_D64alds_v6",
              "Standard_D64als_v6",
              "Standard_D64as_v4",
              "Standard_D64as_v5",
              "Standard_D64as_v6",
              "Standard_D64d_v4",
              "Standard_D64d_v5",
              "Standard_D64ds_v4",
              "Standard_D64ds_v5",
              "Standard_D64ds_v6",
              "Standard_D64lds_v5",
              "Standard_D64lds_v6",
              "Standard_D64ls_v5",
              "Standard_D64ls_v6",
              "Standard_D64pds_v5",
              "Standard_D64pds_v6",
              "Standard_D64plds_v5",
              "Standard_D64plds_v6",
              "Standard_D64pls_v5",
              "Standard_D64pls_v6",
              "Standard_D64ps_v5",
              "Standard_D64ps_v6",
              "Standard_D64s_v3",
              "Standard_D64s_v4",
              "Standard_D64s_v5",
              "Standard_D64s_v6",
              "Standard_D8_v3",
              "Standard_D8_v4",
              "Standard_D8_v5",
              "Standard_D8a_v4",
              "Standard_D8ads_v5",
              "Standard_D8ads_v6",
              "Standard_D8alds_v6",
              "Standard_D8als_v6",
              "Standard_D8as_v4",
              "Standard_D8as_v5",
              "Standard_D8as_v6",
              "Standard_D8d_v4",
              "Standard_D8d_v5",
              "Standard_D8ds_v4",
              "Standard_D8ds_v5",
              "Standard_D8ds_v6",
              "Standard_D8lds_v5",
              "Standard_D8lds_v6",
              "Standard_D8ls_v5",
              "Standard_D8ls_v6",
              "Standard_D8pds_v5",
              "Standard_D8pds_v6",
              "Standard_D8plds_v5",
              "Standard_D8plds_v6",
              "Standard_D8pls_v5",
              "Standard_D8pls_v6",
              "Standard_D8ps_v5",
              "Standard_D8ps_v6",
              "Standard_D8s_v3",
              "Standard_D8s_v4",
              "Standard_D8s_v5",
              "Standard_D8s_v6",
              "Standard_D96_v5",
              "Standard_D96a_v4",
              "Standard_D96ads_v5",
              "Standard_D96ads_v6",
              "Standard_D96alds_v6",
              "Standard_D96als_v6",
              "Standard_D96as_v4",
              "Standard_D96as_v5",
              "Standard_D96as_v6",
              "Standard_D96d_v5",
              "Standard_D96ds_v5",
              "Standard_D96ds_v6",
              "Standard_D96lds_v5",
              "Standard_D96lds_v6",
              "Standard_D96ls_v5",
              "Standard_D96ls_v6",
              "Standard_D96pds_v6",
              "Standard_D96plds_v6",
              "Standard_D96pls_v6",
              "Standard_D96ps_v6",
              "Standard_D96s_v5",
              "Standard_D96s_v6",
              "Standard_DC16ads_cc_v5",
              "Standard_DC16ads_v5",
              "Standard_DC16ads_v6",
              "Standard_DC16as_cc_v5",
              "Standard_DC16as_v5",
              "Standard_DC16as_v6",
              "Standard_DC16ds_v3",
              "Standard_DC16eds_v5",
              "Standard_DC16es_v5",
              "Standard_DC16s_v3",
              "Standard_DC1ds_v3",
              "Standard_DC1s_v2",
              "Standard_DC1s_v3",
              "Standard_DC24ds_v3",
              "Standard_DC24s_v3",
              "Standard_DC2ads_v5",
              "Standard_DC2ads_v6",
              "Standard_DC2as_v5",
              "Standard_DC2as_v6",
              "Standard_DC2ds_v3",
              "Standard_DC2eds_v5",
              "Standard_DC2es_v5",
              "Standard_DC2s",
              "Standard_DC2s_v2",
              "Standard_DC2s_v3",
              "Standard_DC32ads_cc_v5",
              "Standard_DC32ads_v5",
              "Standard_DC32ads_v6",
              "Standard_DC32as_cc_v5",
              "Standard_DC32as_v5",
              "Standard_DC32as_v6",
              "Standard_DC32ds_v3",
              "Standard_DC32eds_v5",
              "Standard_DC32es_v5",
              "Standard_DC32s_v3",
              "Standard_DC48ads_cc_v5",
              "Standard_DC48ads_v5",
              "Standard_DC48ads_v6",
              "Standard_DC48as_cc_v5",
              "Standard_DC48as_v5",
              "Standard_DC48as_v6",
              "Standard_DC48ds_v3",
              "Standard_DC48eds_v5",
              "Standard_DC48es_v5",
              "Standard_DC48s_v3",
              "Standard_DC4ads_cc_v5",
              "Standard_DC4ads_v5",
              "Standard_DC4ads_v6",
              "Standard_DC4as_cc_v5",
              "Standard_DC4as_v5",
              "Standard_DC4as_v6",
              "Standard_DC4ds_v3",
              "Standard_DC4eds_v5",
              "Standard_DC4es_v5",
              "Standard_DC4s",
              "Standard_DC4s_v2",
              "Standard_DC4s_v3",
              "Standard_DC64ads_cc_v5",
              "Standard_DC64ads_v5",
              "Standard_DC64ads_v6",
              "Standard_DC64as_cc_v5",
              "Standard_DC64as_v5",
              "Standard_DC64as_v6",
              "Standard_DC64eds_v5",
              "Standard_DC64es_v5",
              "Standard_DC8_v2",
              "Standard_DC8ads_cc_v5",
              "Standard_DC8ads_v5",
              "Standard_DC8ads_v6",
              "Standard_DC8as_cc_v5",
              "Standard_DC8as_v5",
              "Standard_DC8as_v6",
              "Standard_DC8ds_v3",
              "Standard_DC8eds_v5",
              "Standard_DC8es_v5",
              "Standard_DC8s",
              "Standard_DC8s_v3",
              "Standard_DC96ads_cc_v5",
              "Standard_DC96ads_v5",
              "Standard_DC96ads_v6",
              "Standard_DC96as_cc_v5",
              "Standard_DC96as_v5",
              "Standard_DC96as_v6",
              "Standard_DC96eds_v5",
              "Standard_DC96es_v5",
              "Standard_DS1",
              "Standard_DS11",
              "Standard_DS11-1_v2",
              "Standard_DS11_v2",
              "Standard_DS11_v2_Promo",
              "Standard_DS12",
              "Standard_DS12-1_v2",
              "Standard_DS12-2_v2",
              "Standard_DS12_v2",
              "Standard_DS12_v2_Promo",
              "Standard_DS13",
              "Standard_DS13-2_v2",
              "Standard_DS13-4_v2",
              "Standard_DS13_v2",
              "Standard_DS13_v2_Promo",
              "Standard_DS14",
              "Standard_DS14-4_v2",
              "Standard_DS14-8_v2",
              "Standard_DS14_v2",
              "Standard_DS14_v2_Promo",
              "Standard_DS15_v2",
              "Standard_DS1_v2",
              "Standard_DS2",
              "Standard_DS2_v2",
              "Standard_DS2_v2_Promo",
              "Standard_DS3",
              "Standard_DS3_v2",
              "Standard_DS3_v2_Promo",
              "Standard_DS4",
              "Standard_DS4_v2",
              "Standard_DS4_v2_Promo",
              "Standard_DS5_v2",
              "Standard_DS5_v2_Promo",
              "Standard_E104i_v5",
              "Standard_E104id_v5",
              "Standard_E104ids_v5",
              "Standard_E104is_v5",
              "Standard_E112iads_v5",
              "Standard_E112ias_v5",
              "Standard_E112ibds_v5",
              "Standard_E112ibs_v5",
              "Standard_E128-32ds_v6",
              "Standard_E128-32s_v6",
              "Standard_E128-64ds_v6",
              "Standard_E128-64s_v6",
              "Standard_E128ds_v6",
              "Standard_E128s_v6",
              "Standard_E16-4ads_v5",
              "Standard_E16-4as_v4",
              "Standard_E16-4as_v5",
              "Standard_E16-4ds_v4",
              "Standard_E16-4ds_v5",
              "Standard_E16-4ds_v6",
              "Standard_E16-4s_v3",
              "Standard_E16-4s_v4",
              "Standard_E16-4s_v5",
              "Standard_E16-4s_v6",
              "Standard_E16-8ads_v5",
              "Standard_E16-8as_v4",
              "Standard_E16-8as_v5",
              "Standard_E16-8ds_v4",
              "Standard_E16-8ds_v5",
              "Standard_E16-8ds_v6",
              "Standard_E16-8s_v3",
              "Standard_E16-8s_v4",
              "Standard_E16-8s_v5",
              "Standard_E16-8s_v6",
              "Standard_E16_v3",
              "Standard_E16_v4",
              "Standard_E16_v5",
              "Standard_E16a_v4",
              "Standard_E16ads_v5",
              "Standard_E16ads_v6",
              "Standard_E16as_v4",
              "Standard_E16as_v5",
              "Standard_E16as_v6",
              "Standard_E16bds_v5",
              "Standard_E16bs_v5",
              "Standard_E16d_v4",
              "Standard_E16d_v5",
              "Standard_E16ds_v4",
              "Standard_E16ds_v5",
              "Standard_E16ds_v6",
              "Standard_E16pds_v5",
              "Standard_E16pds_v6",
              "Standard_E16ps_v5",
              "Standard_E16ps_v6",
              "Standard_E16s_v3",
              "Standard_E16s_v4",
              "Standard_E16s_v5",
              "Standard_E16s_v6",
              "Standard_E192ids_v6",
              "Standard_E192is_v6",
              "Standard_E20_v3",
              "Standard_E20_v4",
              "Standard_E20_v5",
              "Standard_E20a_v4",
              "Standard_E20ads_v5",
              "Standard_E20ads_v6",
              "Standard_E20as_v4",
              "Standard_E20as_v5",
              "Standard_E20as_v6",
              "Standard_E20d_v4",
              "Standard_E20d_v5",
              "Standard_E20ds_v4",
              "Standard_E20ds_v5",
              "Standard_E20ds_v6",
              "Standard_E20pds_v5",
              "Standard_E20ps_v5",
              "Standard_E20s_v3",
              "Standard_E20s_v4",
              "Standard_E20s_v5",
              "Standard_E20s_v6",
              "Standard_E2_v3",
              "Standard_E2_v4",
              "Standard_E2_v5",
              "Standard_E2a_v4",
              "Standard_E2ads_v5",
              "Standard_E2ads_v6",
              "Standard_E2as_v4",
              "Standard_E2as_v5",
              "Standard_E2as_v6",
              "Standard_E2bds_v5",
              "Standard_E2bs_v5",
              "Standard_E2d_v4",
              "Standard_E2d_v5",
              "Standard_E2ds_v4",
              "Standard_E2ds_v5",
              "Standard_E2ds_v6",
              "Standard_E2pds_v5",
              "Standard_E2pds_v6",
              "Standard_E2ps_v5",
              "Standard_E2ps_v6",
              "Standard_E2s_v3",
              "Standard_E2s_v4",
              "Standard_E2s_v5",
              "Standard_E2s_v6",
              "Standard_E32-16ads_v5",
              "Standard_E32-16as_v4",
              "Standard_E32-16as_v5",
              "Standard_E32-16ds_v4",
              "Standard_E32-16ds_v5",
              "Standard_E32-16ds_v6",
              "Standard_E32-16s_v3",
              "Standard_E32-16s_v4",
              "Standard_E32-16s_v5",
              "Standard_E32-16s_v6",
              "Standard_E32-8ads_v5",
              "Standard_E32-8as_v4",
              "Standard_E32-8as_v5",
              "Standard_E32-8ds_v4",
              "Standard_E32-8ds_v5",
              "Standard_E32-8ds_v6",
              "Standard_E32-8s_v3",
              "Standard_E32-8s_v4",
              "Standard_E32-8s_v5",
              "Standard_E32-8s_v6",
              "Standard_E32_v3",
              "Standard_E32_v4",
              "Standard_E32_v5",
              "Standard_E32a_v4",
              "Standard_E32ads_v5",
              "Standard_E32ads_v6",
              "Standard_E32as_v4",
              "Standard_E32as_v5",
              "Standard_E32as_v6",
              "Standard_E32bds_v5",
              "Standard_E32bs_v5",
              "Standard_E32d_v4",
              "Standard_E32d_v5",
              "Standard_E32ds_v4",
              "Standard_E32ds_v5",
              "Standard_E32ds_v6",
              "Standard_E32pds_v5",
              "Standard_E32pds_v6",
              "Standard_E32ps_v5",
              "Standard_E32ps_v6",
              "Standard_E32s_v3",
              "Standard_E32s_v4",
              "Standard_E32s_v5",
              "Standard_E32s_v6",
              "Standard_E4-2ads_v5",
              "Standard_E4-2as_v4",
              "Standard_E4-2as_v5",
              "Standard_E4-2ds_v4",
              "Standard_E4-2ds_v5",
              "Standard_E4-2ds_v6",
              "Standard_E4-2s_v3",
              "Standard_E4-2s_v4",
              "Standard_E4-2s_v5",
              "Standard_E4-2s_v6",
              "Standard_E48_v3",
              "Standard_E48_v4",
              "Standard_E48_v5",
              "Standard_E48a_v4",
              "Standard_E48ads_v5",
              "Standard_E48ads_v6",
              "Standard_E48as_v4",
              "Standard_E48as_v5",
              "Standard_E48as_v6",
              "Standard_E48bds_v5",
              "Standard_E48bs_v5",
              "Standard_E48d_v4",
              "Standard_E48d_v5",
              "Standard_E48ds_v4",
              "Standard_E48ds_v5",
              "Standard_E48ds_v6",
              "Standard_E48pds_v6",
              "Standard_E48ps_v6",
              "Standard_E48s_v3",
              "Standard_E48s_v4",
              "Standard_E48s_v5",
              "Standard_E48s_v6",
              "Standard_E4_v3",
              "Standard_E4_v4",
              "Standard_E4_v5",
              "Standard_E4a_v4",
              "Standard_E4ads_v5",
              "Standard_E4ads_v6",
              "Standard_E4as_v4",
              "Standard_E4as_v5",
              "Standard_E4as_v6",
              "Standard_E4bds_v5",
              "Standard_E4bs_v5",
              "Standard_E4d_v4",
              "Standard_E4d_v5",
              "Standard_E4ds_v4",
              "Standard_E4ds_v5",
              "Standard_E4ds_v6",
              "Standard_E4pds_v5",
              "Standard_E4pds_v6",
              "Standard_E4ps_v5",
              "Standard_E4ps_v6",
              "Standard_E4s_v3",
              "Standard_E4s_v4",
              "Standard_E4s_v5",
              "Standard_E4s_v6",
              "Standard_E64-16ads_v5",
              "Standard_E64-16as_v4",
              "Standard_E64-16as_v5",
              "Standard_E64-16ds_v4",
              "Standard_E64-16ds_v5",
              "Standard_E64-16ds_v6",
              "Standard_E64-16s_v3",
              "Standard_E64-16s_v4",
              "Standard_E64-16s_v5",
              "Standard_E64-16s_v6",
              "Standard_E64-32ads_v5",
              "Standard_E64-32as_v4",
              "Standard_E64-32as_v5",
              "Standard_E64-32ds_v4",
              "Standard_E64-32ds_v5",
              "Standard_E64-32ds_v6",
              "Standard_E64-32s_v3",
              "Standard_E64-32s_v4",
              "Standard_E64-32s_v5",
              "Standard_E64-32s_v6",
              "Standard_E64_v3",
              "Standard_E64_v4",
              "Standard_E64_v5",
              "Standard_E64a_v4",
              "Standard_E64ads_v5",
              "Standard_E64ads_v6",
              "Standard_E64as_v4",
              "Standard_E64as_v5",
              "Standard_E64as_v6",
              "Standard_E64bds_v5",
              "Standard_E64bs_v5",
              "Standard_E64d_v4",
              "Standard_E64d_v5",
              "Standard_E64ds_v4",
              "Standard_E64ds_v5",
              "Standard_E64ds_v6",
              "Standard_E64i_v3",
              "Standard_E64is_v3",
              "Standard_E64pds_v6",
              "Standard_E64ps_v6",
              "Standard_E64s_v3",
              "Standard_E64s_v4",
              "Standard_E64s_v5",
              "Standard_E64s_v6",
              "Standard_E8-2ads_v5",
              "Standard_E8-2as_v4",
              "Standard_E8-2as_v5",
              "Standard_E8-2ds_v4",
              "Standard_E8-2ds_v5",
              "Standard_E8-2ds_v6",
              "Standard_E8-2s_v3",
              "Standard_E8-2s_v4",
              "Standard_E8-2s_v5",
              "Standard_E8-2s_v6",
              "Standard_E8-4ads_v5",
              "Standard_E8-4as_v4",
              "Standard_E8-4as_v5",
              "Standard_E8-4ds_v4",
              "Standard_E8-4ds_v5",
              "Standard_E8-4ds_v6",
              "Standard_E8-4s_v3",
              "Standard_E8-4s_v4",
              "Standard_E8-4s_v5",
              "Standard_E8-4s_v6",
              "Standard_E80ids_v4",
              "Standard_E80is_v4",
              "Standard_E8_v3",
              "Standard_E8_v4",
              "Standard_E8_v5",
              "Standard_E8a_v4",
              "Standard_E8ads_v5",
              "Standard_E8ads_v6",
              "Standard_E8as_v4",
              "Standard_E8as_v5",
              "Standard_E8as_v6",
              "Standard_E8bds_v5",
              "Standard_E8bs_v5",
              "Standard_E8d_v4",
              "Standard_E8d_v5",
              "Standard_E8ds_v4",
              "Standard_E8ds_v5",
              "Standard_E8ds_v6",
              "Standard_E8pds_v5",
              "Standard_E8pds_v6",
              "Standard_E8ps_v5",
              "Standard_E8ps_v6",
              "Standard_E8s_v3",
              "Standard_E8s_v4",
              "Standard_E8s_v5",
              "Standard_E8s_v6",
              "Standard_E96-24ads_v5",
              "Standard_E96-24ads_v6",
              "Standard_E96-24as_v4",
              "Standard_E96-24as_v5",
              "Standard_E96-24ds_v5",
              "Standard_E96-24ds_v6",
              "Standard_E96-24s_v5",
              "Standard_E96-24s_v6",
              "Standard_E96-48ads_v5",
              "Standard_E96-48ads_v6",
              "Standard_E96-48as_v4",
              "Standard_E96-48as_v5",
              "Standard_E96-48ds_v5",
              "Standard_E96-48ds_v6",
              "Standard_E96-48s_v5",
              "Standard_E96-48s_v6",
              "Standard_E96_v5",
              "Standard_E96a_v4",
              "Standard_E96ads_v5",
              "Standard_E96ads_v6",
              "Standard_E96as_v4",
              "Standard_E96as_v5",
              "Standard_E96as_v6",
              "Standard_E96bds_v5",
              "Standard_E96bs_v5",
              "Standard_E96d_v5",
              "Standard_E96ds_v5",
              "Standard_E96ds_v6",
              "Standard_E96ias_v4",
              "Standard_E96pds_v6",
              "Standard_E96ps_v6",
              "Standard_E96s_v5",
              "Standard_E96s_v6",
              "Standard_EC128eds_v5",
              "Standard_EC128es_v5",
              "Standard_EC128ieds_v5",
              "Standard_EC128ies_v5",
              "Standard_EC16ads_cc_v5",
              "Standard_EC16ads_v5",
              "Standard_EC16ads_v6",
              "Standard_EC16as_cc_v5",
              "Standard_EC16as_v5",
              "Standard_EC16as_v6",
              "Standard_EC16eds_v5",
              "Standard_EC16es_v5",
              "Standard_EC20ads_cc_v5",
              "Standard_EC20ads_v5",
              "Standard_EC20as_cc_v5",
              "Standard_EC20as_v5",
              "Standard_EC2ads_v5",
              "Standard_EC2ads_v6",
              "Standard_EC2as_v5",
              "Standard_EC2as_v6",
              "Standard_EC2eds_v5",
              "Standard_EC2es_v5",
              "Standard_EC32ads_cc_v5",
              "Standard_EC32ads_v5",
              "Standard_EC32ads_v6",
              "Standard_EC32as_cc_v5",
              "Standard_EC32as_v5",
              "Standard_EC32as_v6",
              "Standard_EC32eds_v5",
              "Standard_EC32es_v5",
              "Standard_EC48ads_cc_v5",
              "Standard_EC48ads_v5",
              "Standard_EC48ads_v6",
              "Standard_EC48as_cc_v5",
              "Standard_EC48as_v5",
              "Standard_EC48as_v6",
              "Standard_EC48eds_v5",
              "Standard_EC48es_v5",
              "Standard_EC4ads_cc_v5",
              "Standard_EC4ads_v5",
              "Standard_EC4ads_v6",
              "Standard_EC4as_cc_v5",
              "Standard_EC4as_v5",
              "Standard_EC4as_v6",
              "Standard_EC4eds_v5",
              "Standard_EC4es_v5",
              "Standard_EC64ads_cc_v5",
              "Standard_EC64ads_v5",
              "Standard_EC64ads_v6",
              "Standard_EC64as_cc_v5",
              "Standard_EC64as_v5",
              "Standard_EC64as_v6",
              "Standard_EC64eds_v5",
              "Standard_EC64es_v5",
              "Standard_EC8ads_cc_v5",
              "Standard_EC8ads_v5",
              "Standard_EC8ads_v6",
              "Standard_EC8as_cc_v5",
              "Standard_EC8as_v5",
              "Standard_EC8as_v6",
              "Standard_EC8eds_v5",
              "Standard_EC8es_v5",
              "Standard_EC96ads_cc_v5",
              "Standard_EC96ads_v5",
              "Standard_EC96ads_v6",
              "Standard_EC96as_cc_v5",
              "Standard_EC96as_v5",
              "Standard_EC96as_v6",
              "Standard_EC96iads_v5",
              "Standard_EC96ias_v5",
              "Standard_F1",
              "Standard_F16",
              "Standard_F16als_v6",
              "Standard_F16ams_v6",
              "Standard_F16as_v6",
              "Standard_F16s",
              "Standard_F16s_v2",
              "Standard_F1s",
              "Standard_F2",
              "Standard_F2als_v6",
              "Standard_F2ams_v6",
              "Standard_F2as_v6",
              "Standard_F2s",
              "Standard_F2s_v2",
              "Standard_F32als_v6",
              "Standard_F32ams_v6",
              "Standard_F32as_v6",
              "Standard_F32s_v2",
              "Standard_F4",
              "Standard_F48als_v6",
              "Standard_F48ams_v6",
              "Standard_F48as_v6",
              "Standard_F48s_v2",
              "Standard_F4als_v6",
              "Standard_F4ams_v6",
              "Standard_F4as_v6",
              "Standard_F4s",
              "Standard_F4s_v2",
              "Standard_F64als_v6",
              "Standard_F64ams_v6",
              "Standard_F64as_v6",
              "Standard_F64s_v2",
              "Standard_F72s_v2",
              "Standard_F8",
              "Standard_F8als_v6",
              "Standard_F8ams_v6",
              "Standard_F8as_v6",
              "Standard_F8s",
              "Standard_F8s_v2",
              "Standard_FX12-6mds_v2",
              "Standard_FX12-6ms_v2",
              "Standard_FX12mds",
              "Standard_FX12mds_v2",
              "Standard_FX12ms_v2",
              "Standard_FX16-4mds_v2",
              "Standard_FX16-4ms_v2",
              "Standard_FX16-8mds_v2",
              "Standard_FX16-8ms_v2",
              "Standard_FX16mds_v2",
              "Standard_FX16ms_v2",
              "Standard_FX24-12mds_v2",
              "Standard_FX24-12ms_v2",
              "Standard_FX24-6mds_v2",
              "Standard_FX24-6ms_v2",
              "Standard_FX24mds",
              "Standard_FX24mds_v2",
              "Standard_FX24ms_v2",
              "Standard_FX2mds_v2",
              "Standard_FX2ms_v2",
              "Standard_FX32-16mds_v2",
              "Standard_FX32-16ms_v2",
              "Standard_FX32-8mds_v2",
              "Standard_FX32-8ms_v2",
              "Standard_FX32mds_v2",
              "Standard_FX32ms_v2",
              "Standard_FX36mds",
              "Standard_FX4-2mds_v2",
              "Standard_FX4-2ms_v2",
              "Standard_FX48-12mds_v2",
              "Standard_FX48-12ms_v2",
              "Standard_FX48-24mds_v2",
              "Standard_FX48-24ms_v2",
              "Standard_FX48mds",
              "Standard_FX48mds_v2",
              "Standard_FX48ms_v2",
              "Standard_FX4mds",
              "Standard_FX4mds_v2",
              "Standard_FX4ms_v2",
              "Standard_FX64-16mds_v2",
              "Standard_FX64-16ms_v2",
              "Standard_FX64-32mds_v2",
              "Standard_FX64-32ms_v2",
              "Standard_FX64mds_v2",
              "Standard_FX64ms_v2",
              "Standard_FX8-2mds_v2",
              "Standard_FX8-2ms_v2",
              "Standard_FX8-4mds_v2",
              "Standard_FX8-4ms_v2",
              "Standard_FX8mds_v2",
              "Standard_FX8ms_v2",
              "Standard_FX96-24mds_v2",
              "Standard_FX96-24ms_v2",
              "Standard_FX96-48mds_v2",
              "Standard_FX96-48ms_v2",
              "Standard_FX96mds_v2",
              "Standard_FX96ms_v2",
              "Standard_H16",
              "Standard_H16_Promo",
              "Standard_H16m",
              "Standard_H16m_Promo",
              "Standard_H16mr",
              "Standard_H16mr_Promo",
              "Standard_H16r",
              "Standard_H16r_Promo",
              "Standard_H8",
              "Standard_H8_Promo",
              "Standard_H8m",
              "Standard_H8m_Promo",
              "Standard_Internal_ND80sr_MS_v1",
              "Standard_L12aos_v4",
              "Standard_L16aos_v4",
              "Standard_L16as_v4",
              "Standard_L16s_v2",
              "Standard_L16s_v3",
              "Standard_L16s_v4",
              "Standard_L24aos_v4",
              "Standard_L2aos_v4",
              "Standard_L2as_v4",
              "Standard_L2s_v4",
              "Standard_L32aos_v4",
              "Standard_L32as_v4",
              "Standard_L32s_v4",
              "Standard_L48as_v4",
              "Standard_L48s_v4",
              "Standard_L4aos_v4",
              "Standard_L4as_v4",
              "Standard_L4s_v4",
              "Standard_L64as_v4",
              "Standard_L64s_v4",
              "Standard_L80as_v4",
              "Standard_L80s_v4",
              "Standard_L8aos_v4",
              "Standard_L8as_v4",
              "Standard_L8s_v4",
              "Standard_L96as_v4",
              "Standard_L96s_v4",
              "Standard_M128",
              "Standard_M128-32ms",
              "Standard_M128-64bds_3_v3",
              "Standard_M128-64bds_v3",
              "Standard_M128-64bs_v3",
              "Standard_M128-64ms",
              "Standard_M128bds_3_v3",
              "Standard_M128bds_v3",
              "Standard_M128bs_v3",
              "Standard_M128dms_v2",
              "Standard_M128ds_v2",
              "Standard_M128m",
              "Standard_M128ms",
              "Standard_M128ms_v2",
              "Standard_M128s",
              "Standard_M128s_v2",
              "Standard_M12ds_v3",
              "Standard_M12s_v3",
              "Standard_M16-4ms",
              "Standard_M16-8ms",
              "Standard_M16bds_v3",
              "Standard_M16bs_v3",
              "Standard_M16ms",
              "Standard_M176-88bds_4_v3",
              "Standard_M176-88bds_v3",
              "Standard_M176-88bs_v3",
              "Standard_M176bds_4_v3",
              "Standard_M176bds_v3",
              "Standard_M176bs_v3",
              "Standard_M176ds_3_v3",
              "Standard_M176ds_4_v3",
              "Standard_M176s_3_v3",
              "Standard_M176s_4_v3",
              "Standard_M192idms_v2",
              "Standard_M192ids_v2",
              "Standard_M192ims_v2",
              "Standard_M192is_v2",
              "Standard_M208ms_v2",
              "Standard_M208s_v2",
              "Standard_M24ds_v3",
              "Standard_M24s_v3",
              "Standard_M32-16ms",
              "Standard_M32-8ms",
              "Standard_M32bds_v3",
              "Standard_M32bs_v3",
              "Standard_M32dms_v2",
              "Standard_M32ls",
              "Standard_M32ms",
              "Standard_M32ms_v2",
              "Standard_M32ts",
              "Standard_M416-208ms_v2",
              "Standard_M416-208s_v2",
              "Standard_M416ds_6_v3",
              "Standard_M416ds_8_v3",
              "Standard_M416ms_v2",
              "Standard_M416s_10_v2",
              "Standard_M416s_6_v3",
              "Standard_M416s_8_v2",
              "Standard_M416s_8_v3",
              "Standard_M416s_9_v2",
              "Standard_M416s_v2",
              "Standard_M48bds_v3",
              "Standard_M48bs_v3",
              "Standard_M48ds_1_v3",
              "Standard_M48s_1_v3",
              "Standard_M624ds_12_v3",
              "Standard_M624s_12_v3",
              "Standard_M64",
              "Standard_M64-16ms",
              "Standard_M64-32bds_1_v3",
              "Standard_M64-32ms",
              "Standard_M64bds_1_v3",
              "Standard_M64bds_v3",
              "Standard_M64bs_v3",
              "Standard_M64dms_v2",
              "Standard_M64ds_v2",
              "Standard_M64ls",
              "Standard_M64m",
              "Standard_M64ms",
              "Standard_M64ms_v2",
              "Standard_M64s",
              "Standard_M64s_v2",
              "Standard_M8-2ms",
              "Standard_M8-4ms",
              "Standard_M832ds_12_v3",
              "Standard_M832ids_16_v3",
              "Standard_M832is_16_v3",
              "Standard_M832s_12_v3",
              "Standard_M8ms",
              "Standard_M96-48bds_2_v3",
              "Standard_M96bds_2_v3",
              "Standard_M96bds_v3",
              "Standard_M96bs_v3",
              "Standard_M96ds_1_v3",
              "Standard_M96ds_2_v3",
              "Standard_M96s_1_v3",
              "Standard_M96s_2_v3",
              "Standard_NC12",
              "Standard_NC12_Promo",
              "Standard_NC12s_v2",
              "Standard_NC24",
              "Standard_NC24_Promo",
              "Standard_NC24r",
              "Standard_NC24r_Promo",
              "Standard_NC24rs_v2",
              "Standard_NC24s_v2",
              "Standard_NC6",
              "Standard_NC6_Promo",
              "Standard_NC6s_v2",
              "Standard_ND12s",
              "Standard_ND24rs",
              "Standard_ND24s",
              "Standard_ND6s",
              "Standard_ND96isr_MI300X_v5",
              "Standard_NV10ads_A10_v5",
              "Standard_NV12",
              "Standard_NV12_Promo",
              "Standard_NV20adms_A10_v5",
              "Standard_NV20ads_A10_v5",
              "Standard_NV24",
              "Standard_NV24_Promo",
              "Standard_NV28ads_V710_v5",
              "Standard_NV30adms_A10_v5",
              "Standard_NV30ads_A10_v5",
              "Standard_NV40ads_A10_v5",
              "Standard_NV4ads_A10_v5",
              "Standard_NV4as_v4",
              "Standard_NV6",
              "Standard_NV6_Promo",
              "Standard_PB6s",
            ]
          }
        }
        "PA-Evri-Sec-Baseline"     = { enforcement_mode = "Default" }
        "PA-Evri-Storage-Baseline" = { enforcement_mode = "Default" }
        "PA-Evri-Cost-Baseline"    = { enforcement_mode = "Default" }
        "Win-VM-Eventlogs-DCR" = {
          parameters = {
            dcrResourceId = "$${scc_custom_windows_eventlogs_data_collection_rule_id}"
          }
        }
        "Audit-VM-Backups"        = { enforcement_mode = "Default" } # Azure Backup should be enabled for Virtual Machines
        "UK-Official-and-UK-NHS"  = { enforcement_mode = "Default" } # UK OFFICIAL and UK NHS
        "Deny-MgmtPorts-Internet" = { enforcement_mode = "Default" } # Management port access from the Internet should be blocked
        "Deny-Subnet-Without-Nsg" = {
          enforcement_mode = "Default"
          parameters = {
            excludedSubnets = [
              "GatewaySubnet",
              "AzureFirewallSubnet",
              "AzureFirewallManagementSubnet",
              "AzureBastionSubnet",
              "RouteServerSubnet"
            ]
          }
        } # Subnets should have a Network Security Group
        "CIS-Msft-Benchmark-v2" = {
          parameters = {
            maximumDaysToRotate-d8cf8476-a2ec-4916-896e-992351803c44 = 90
          },
          enforcement_mode = "Default"
        } # CIS Microsoft Azure Foundations Benchmark v2.0.0
      }
    }

    "evri-platform" = {
      policy_assignments = {
        # ALZ inbuilt assignments ----------------------------------------------
        "DenyAction-DeleteUAMIAMA" = { enforcement_mode = "Default" }      # Do not allow deletion of the User Assigned Managed Identity used by AMA
        "Deploy-GuestAttest"       = { enforcement_mode = "DoNotEnforce" } # Configure prerequisites to enable Guest Attestation on Trusted Launch enabled VMs
        "Deploy-MDFC-DefSQL-AMA"   = { enforcement_mode = "DoNotEnforce" } # Enable Defender for SQL on SQL VMs and Arc-enabled SQL Servers
        "Deploy-VM-ChangeTrack"    = { enforcement_mode = "Default" }      # Enable ChangeTracking and Inventory for virtual machines
        "Deploy-VM-Monitoring"     = { enforcement_mode = "Default" }      # Enable Azure Monitor for VMs
        "Deploy-vmArc-ChangeTrack" = { enforcement_mode = "Default" }      # Enable ChangeTracking and Inventory for Arc-enabled virtual machines
        "Deploy-vmHybr-Monitoring" = { enforcement_mode = "Default" }      # Enable Azure Monitor for Hybrid Virtual Machines
        "Deploy-VMSS-ChangeTrack"  = { enforcement_mode = "Default" }      # Enable ChangeTracking and Inventory for virtual machine scale sets
        "Deploy-VMSS-Monitoring"   = { enforcement_mode = "Default" }      # Enable Azure Monitor for Virtual Machine Scale Sets
        "Enable-AUM-CheckUpdates"  = { enforcement_mode = "Default" }      # Configure periodic checking for missing system updates on azure virtual machines and Arc-enabled virtual machines.
        "Enforce-ASR"              = { enforcement_mode = "DoNotEnforce" } # Enforce enhanced recovery and backup policies
        "Enforce-Encrypt-CMK0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Customer Managed Keys

        "Enforce-GR-APIM0"        = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for API Management
        "Enforce-GR-AppServices0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for App Services
        "Enforce-GR-Automation0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Automation Accounts
        "Enforce-GR-BotService0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Bot Service
        "Enforce-GR-CogServ0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Cognitive Services
        "Enforce-GR-Compute0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Compute
        "Enforce-GR-ContApps0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Apps
        "Enforce-GR-ContInst0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Instance
        "Enforce-GR-ContReg0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Registry
        "Enforce-GR-CosmosDb0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Cosmos DB
        "Enforce-GR-DataExpl0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Data Explorer
        "Enforce-GR-DataFactory0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Data Factory
        "Enforce-GR-EventGrid0"   = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Event Grid
        "Enforce-GR-EventHub0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Event Hub
        "Enforce-GR-KeyVault"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Azure Key Vault
        "Enforce-GR-KeyVaultSup0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Key Vault Supplementary
        "Enforce-GR-Kubernetes0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Kubernetes
        "Enforce-GR-MachLearn0"   = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Machine Learning
        "Enforce-GR-MySQL0"       = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for MySQL
        "Enforce-GR-Network0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Network and Networking services
        "Enforce-GR-OpenAI0"      = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for OpenAI
        "Enforce-GR-PostgreSQL0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for PostgreSQL
        "Enforce-GR-ServiceBus0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Service Bus
        "Enforce-GR-SQL0"         = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for SQL
        "Enforce-GR-Storage0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Storage
        "Enforce-GR-Synapse0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Synapse
        "Enforce-GR-VirtualDesk0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Virtual Desktop
        "Enforce-Subnet-Private"  = { enforcement_mode = "Default" }      # Subnets should be private
      }
    }

    # "evri-landingzones" = {
    #   policy_assignments = {
    #     # ALZ inbuilt assignments ----------------------------------------------
    #     "Audit-AppGW-WAF"          = { enforcement_mode = "Default" } # Audit that Web Application Firewall (WAF) is enabled for Application Gateway
    #     "Deny-IP-forwarding"       = { enforcement_mode = "Default" } # Deny network interfaces with IP forwarding enabled
    #     "Deny-MgmtPorts-Internet"  = { enforcement_mode = "Default" } # Deny NSG rules that expose management ports to the Internet
    #     "Deny-Priv-Esc-AKS"        = { enforcement_mode = "DoNotEnforce" } # Deny containers that allow privilege escalation in AKS
    #     "Deny-Privileged-AKS"      = { enforcement_mode = "DoNotEnforce" } # Deny privileged containers in AKS
    #     "Deny-Storage-http"        = { enforcement_mode = "DoNotEnforce" } # Deny storage accounts without secure transfer (HTTPS) enabled
    #     "Deny-Subnet-Without-Nsg"  = { enforcement_mode = "Default" } # Deny subnets that do not have a Network Security Group attached
    #     "Deploy-AzSqlDb-Auditing"  = { enforcement_mode = "DoNotEnforce" } # Enable SQL Server auditing to a Log Analytics workspace
    #     "Deploy-GuestAttest"       = { enforcement_mode = "DoNotEnforce" } # Install Guest Attestation extension on Trusted Launch–enabled VMs
    #     "Deploy-MDFC-DefSQL-AMA"   = { enforcement_mode = "DoNotEnforce" } # Enable Defender for SQL on SQL VMs and Arc-enabled SQL Servers (via AMA/DCR)
    #     "Deploy-SQL-TDE"           = { enforcement_mode = "DoNotEnforce" } # Enable Transparent Data Encryption (TDE) on SQL servers
    #     "Deploy-SQL-Threat"        = { enforcement_mode = "DoNotEnforce" } # Enable SQL Threat Detection (Defender for SQL alerts) on SQL servers
    #     "Deploy-VM-Backup"         = { enforcement_mode = "DoNotEnforce" } # Configure VM backup to a new Recovery Services vault with a default policy
    #     "Deploy-VM-ChangeTrack"    = { enforcement_mode = "Default" } # Configure Windows virtual machines to automatically install the ChangeTracking extension
    #     "Deploy-VM-Monitoring"     = { enforcement_mode = "Default" } # Enable Azure Monitor for VMs using AMA and a Data Collection Rule
    #     "Deploy-vmArc-ChangeTrack" = { enforcement_mode = "Default" } # Enable ChangeTracking and Inventory for Arc-enabled servers
    #     "Deploy-vmHybr-Monitoring" = { enforcement_mode = "Default" } # Enable Azure Monitor for Hybrid (Arc-enabled) Virtual Machines
    #     "Deploy-VMSS-ChangeTrack"  = { enforcement_mode = "Default" } # Enable ChangeTracking and Inventory for Virtual Machine Scale Sets
    #     "Deploy-VMSS-Monitoring"   = { enforcement_mode = "Default" } # Enable Azure Monitor for Virtual Machine Scale Sets using AMA/DCR
    #     "Enable-AUM-CheckUpdates"  = { enforcement_mode = "Default" } # Enable periodic (auto) assessment for missing OS updates on VMs and Arc machines
    #     "Enable-DDoS-VNET"         = { enforcement_mode = "DoNotEnforce" } # Enable Azure DDoS Network Protection on virtual networks
    #     "Enforce-AKS-HTTPS"        = { enforcement_mode = "DoNotEnforce" } # Require Kubernetes clusters (AKS) to be accessible only over HTTPS
    #     "Enforce-ASR"              = { enforcement_mode = "DoNotEnforce" } # Enforce enhanced recovery and backup policies (Azure Backup/Site Recovery)
    #     "Enforce-Encrypt-CMK0"     = { enforcement_mode = "DoNotEnforce" } # Enforce guardrails for Customer Managed Keys (encryption at rest)

    #     "Enforce-GR-APIM0"        = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for API Management
    #     "Enforce-GR-AppServices0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for App Services
    #     "Enforce-GR-Automation0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Automation Accounts
    #     "Enforce-GR-BotService0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Bot Service
    #     "Enforce-GR-CogServ0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Cognitive Services
    #     "Enforce-GR-Compute0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Compute
    #     "Enforce-GR-ContApps0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Apps
    #     "Enforce-GR-ContInst0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Instances
    #     "Enforce-GR-ContReg0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Container Registry
    #     "Enforce-GR-CosmosDb0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Cosmos DB
    #     "Enforce-GR-DataExpl0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Data Explorer
    #     "Enforce-GR-DataFactory0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Data Factory
    #     "Enforce-GR-EventGrid0"   = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Event Grid
    #     "Enforce-GR-EventHub0"    = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Event Hub
    #     "Enforce-GR-KeyVault"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Azure Key Vault
    #     "Enforce-GR-KeyVaultSup0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Key Vault (Supplementary)
    #     "Enforce-GR-Kubernetes0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Kubernetes
    #     "Enforce-GR-MachLearn0"   = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Machine Learning
    #     "Enforce-GR-MySQL0"       = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for MySQL
    #     "Enforce-GR-Network0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Network and Networking services
    #     "Enforce-GR-OpenAI0"      = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for OpenAI
    #     "Enforce-GR-PostgreSQL0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for PostgreSQL
    #     "Enforce-GR-ServiceBus0"  = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Service Bus
    #     "Enforce-GR-SQL0"         = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for SQL
    #     "Enforce-GR-Storage0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Storage
    #     "Enforce-GR-Synapse0"     = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Synapse
    #     "Enforce-GR-VirtualDesk0" = { enforcement_mode = "DoNotEnforce" } # Enforce recommended guardrails for Virtual Desktop

    #     "Enforce-Subnet-Private" = { enforcement_mode = "DoNotEnforce" } # Audit subnets to be private (disable default outbound Internet access)
    #     "Enforce-TLS-SSL-Q225"   = { enforcement_mode = "DoNotEnforce" } # Enforce TLS/SSL (encryption in transit) via deny or deploy/append (Q2 2025 initiative)
    #   }
    # }

    # "evri-corp" = {
    #   policy_assignments = {
    #    # ALZ inbuilt assignments ----------------------------------------------
    #     "Audit-PeDnsZones"         = { enforcement_mode = "Default" } # Audit Private Endpoint Private DNS Zone resources in the Corp landing zone # Audit required Private Link Private DNS Zones are present for Private Endpoints
    #     "Deny-HybridNetworking"    = { enforcement_mode = "Default" } # Deny vWAN/ER/VPN gateway resources in the Corp landing zone # Deny vWAN/ExpressRoute/VPN gateway resources in the Corp landing zone
    #     "Deny-Public-Endpoints"    = { enforcement_mode = "DoNotEnforce" } # Require PaaS services to disable public network access # Disable public network access for Azure PaaS services
    #     "Deny-Public-IP-On-NIC"    = { enforcement_mode = "DoNotEnforce" } # Deny NICs with a public IP associated # Deny NICs with an associated Public IP address
    #     "Deploy-Private-DNS-Zones" = { enforcement_mode = "DoNotEnforce" } # Configure Azure PaaS services to use Private DNS zones # Configure Private Endpoints for PaaS services to use Azure Private DNS zones
    #   }
    # }


    "evri-identity" = {
      policy_assignments = {
        # ALZ inbuilt assignments ----------------------------------------------
        "Deny-Public-IP"   = { enforcement_mode = "Default" }      # Deny the creation of public IP
        "Deploy-VM-Backup" = { enforcement_mode = "DoNotEnforce" } # Configure backup on virtual machines without a given tag to a new recovery services vault with a default policy
      }
    }

    "evri-connectivity" = {
      policy_assignments = {
        # ALZ inbuilt assignments ----------------------------------------------
        "Enable-DDoS-VNET" = { enforcement_mode = "DoNotEnforce" } # Virtual networks should be protected by Azure DDoS Network Protection
      }
    }

    "evri-decommissioned" = {
      policy_assignments = {
        # ALZ inbuilt assignments ----------------------------------------------
        "Enforce-ALZ-Decomm" = { enforcement_mode = "Default" } # Enforce ALZ Decommissioned Guardrails
      }
    }

    "evri-sandbox" = {
      policy_assignments = {
        # ALZ inbuilt assignments ----------------------------------------------
        "Enforce-ALZ-Sandbox" = { enforcement_mode = "Default" } # Enforce ALZ Sandbox Guardrails
      }
    }
  }
  management_group_role_assignments = {
    management_owner_role_assignment = {
      management_group_name      = "evri-management"
      role_definition_id_or_name = "Owner"
      principal_id               = "3e48fe15-3935-43b5-8dd6-691ba362a322"
    }
    identity_owner_role_assignment = {
      management_group_name      = "evri-identity"
      role_definition_id_or_name = "Owner"
      principal_id               = "458f5de9-b96d-4311-9c5c-5e73279531e6"
    }
    platform_owner_role_assignment = {
      management_group_name      = "evri-platform"
      role_definition_id_or_name = "Owner"
      principal_id               = "a8e4ff85-dceb-4b77-942d-f8ef88b10509"
    }
    connectivity_owner_role_assignment = {
      management_group_name      = "evri-connectivity"
      role_definition_id_or_name = "Owner"
      principal_id               = "d26af2e2-eddf-4f88-a28b-d02a613e10a4"
    }
  }
  # role_assignment_name_use_random_uuid = false  # Uncomment this for backwards compatibility with previous naming convention
}