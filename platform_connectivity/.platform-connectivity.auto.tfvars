subscription_ids = {
  management   = "f09a5d16-c8db-4d7c-bce4-a2781c659cde"
  connectivity = "91f98b99-3946-4096-8191-1078a530c5fd"
}

starter_locations = ["uksouth", "ukwest"]

starter_locations_short = {
  uksouth = "uks"
  ukwest  = "ukw"
}

naming = {
  env      = "prod"
  workload = "hub"
  instance = "001"
}

network_dns_zone = {
  "visplatform.co.uk" = {
    name                = "visplatform.co.uk"
    resource_group_name = "rg-hub-prod-dns-uks-001"
    enable_telemetry    = true

    a_records = {
      "uks-sbc-01-ms" = {
        name                = "uks-sbc-01.ms"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["20.90.233.126"]
      }
      "ukw-sbc-01-ms" = {
        name                = "ukw-sbc-01.ms"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["20.58.112.64"]
      }
      "uks-sbc-01-prod" = {
        name                = "uks-sbc-01.prod"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["20.90.233.126"]
      }
      "ukw-sbc-01-prod" = {
        name                = "ukw-sbc-01.prod"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["20.58.112.64"]
      }
      "ovoc" = {
        name                = "ovoc"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["20.108.150.98"]
      }
      "ump" = {
        name                = "ump"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records             = ["85.210.217.17"]
      }
    }
    aaaa_records  = {}
    caa_records   = {}
    cname_records = {}
    mx_records    = {}
    ns_records    = {}
    ptr_records   = {}
    srv_records   = {}

    txt_records = {
      "ms_verification" = {
        name                = "@"
        resource_group_name = "rg-hub-prod-dns-uks-001"
        zone_name           = "visplatform.co.uk"
        ttl                 = 3600
        records = {
          "record1" = {
            value = "MS=ms49681444"
          }
        }
      }
    }
  }
}

vms = {}

tags = {
  deployed_by = "terraform"
  source      = "Azure Landing Zones Accelerator"
  Environment = "production"
  Owner       = "platform-team"
  CostCenter  = "IT-Infrastructure"
}
