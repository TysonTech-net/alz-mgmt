locals {
  default_policy_configs = {
    # Blob backup policy definitions
    blob = {
      "Blob-14d" = {
        retention = {
          daily   = 14
          weekly  = 0
          monthly = 0
          yearly  = 0
        }
      },
    },

    # Azure Disk backup policy definitions
    disk = {
      # "Disk-14d" = {
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # }
    },

    # PostgreSQL backup policy definitions
    postgresql = {
      # "PostgreSQL-14d" = {
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # },
    },

    # Kubernetes Cluster backup policy definitions
    kubernetes = {
      # "Kubernetes-14d" = {
      #   retention = {
      #     daily   = 14
      #     weekly  = 0
      #     monthly = 0
      #     yearly  = 0
      #   }
      # },
    },

    # PostgreSQL Flexible Server backup policy definitions
    postgresql_flexible = {
      "PostgreSQLFlexible-14d" = {
        retention = {
          daily   = 14
          weekly  = 0
          monthly = 0
          yearly  = 0
        }
      },
    }
  }
}