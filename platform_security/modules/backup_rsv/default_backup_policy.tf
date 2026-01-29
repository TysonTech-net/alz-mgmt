locals {
  default_policy_configs = {
    vms = {
      "evri-ProdVMs-DailyBackup-0300hrs-30days-Retention-Policy-001" = {
        policy_type = "V1"
        backup = {
          frequency = "Daily"
          time      = "03:00"
        }
        retention = {
          daily   = 30
          weekly  = 0
          monthly = 0
          yearly  = 0
        }
      }
    },

    # Azure Files backup policy definitions
    azfiles = {
      # "AzFiles-14d" = {
      #   backup = {
      #     frequency = "Hourly"
      #     hourly = {
      #       interval        = 4
      #       start_time      = "08:00"
      #       window_duration = 12
      #     }
      #   }
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # },
    }

    # SQL Server in Azure VM backup policies
    sql_server_in_azure_vm = {
      # "SQLServer-14d" = {
      #   full_backup = {
      #     frequency = "Daily"
      #     time      = "21:00"
      #   }
      #   log_backup = {
      #     frequency_in_minutes = 60
      #     retention_days       = 7
      #   }
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # },
    },

    # SAP HANA in Azure VM backup policies
    sap_hana_in_azure_vm = {
      # "SAPHana-14d" = {
      #   full_backup = {
      #     frequency = "Daily"
      #     time      = "21:00"
      #   }
      #   log_backup = {
      #     frequency_in_minutes = 120
      #     retention_days       = 7
      #   }
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # },
    }
  }
}