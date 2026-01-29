# Azure Spoke Network Module (`spoke_network`)

> **This README matches the actual module files you posted (`main.tf`, `variables.tf`, `outputs.tf`).**
> The module creates **one spoke VNet**, its **subnets** (via **AzAPI**), optional **NSGs** and **Route Tables**, and connects the spoke to a **hub VNet (peering)** or a **vWAN hub (vHub connection)**. It can also (optionally) create a **Private DNS zone VNet link with auto‑registration**.  
> **Important**: Subnets do **not** take NSG/RT names directly — they reference **map _keys_** (logical IDs) defined in the `network_security_groups` and `route_tables` inputs. See **“Keyed maps & how subnets reference NSGs/RTs”** below.

---

## ✨ What this module does

- Creates **one Azure Virtual Network (VNet)** inside an **existing Resource Group** you provide.
- Creates **subnets** using the **latest subnet API** via `azapi_resource`.
- Optionally creates **Network Security Groups (NSGs)** and **Route Tables (UDRs)** in the same RG.
- Associates each subnet to an NSG and/or Route Table, **by key** (not by name).
- Connects the spoke to a **hub** via either:
  - **Hub VNet peering** (`hub_mode = "hubvnet"`), including optional **reverse peering** from the hub.
  - **vWAN/vHub connection** (`hub_mode = "vwan"`), with optional routing settings.
- (Optional) Creates a **Private DNS zone virtual network link** with **registration enabled** for auto‑registration.
- Applies **tags** to resources created by the module.
- Exposes outputs for VNet, subnets, NSGs/RTs and hub connectivity artifacts.

> **It does not** create NAT Gateways, diagnostics, or hub resources. Those belong in separate modules.

---

## 🧱 Providers & versions

- Terraform **1.x**
- Providers:
  - `hashicorp/azurerm` (3.x recommended). Uses a **provider alias** `azurerm.connectivity` for resources that must be created in the **hub** subscription/tenant (reverse peering, Private DNS link).
  - `Azure/azapi` (>= **1.12.0**) to call the latest subnet API.

**Root example (providers):**

```hcl
provider "azurerm" {
  features {}
}

# Alias used for hub-side operations (reverse peering / DNS link)
provider "azurerm" {
  alias           = "connectivity"
  features        = {}
  subscription_id = var.hub_subscription_id   # if different
  tenant_id       = var.hub_tenant_id         # if different
}
```

In the module block you must pass both providers:

```hcl
module "spoke_network" {
  source = "../_modules/spoke_network"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  # ...inputs...
}
```

---

## 🔑 Keyed maps & how subnets reference NSGs/RTs (IMPORTANT)

The module expects **maps** for NSGs and Route Tables, and each subnet **points to those maps using the map _key_** — not the resource name.

### 1) Define your NSGs and RTs as maps

```hcl
network_security_groups = {
  default = {
    name = "nsg-my-spoke-mgmt-uks-001"
    security_rules = []  # (optional)
    tags = {}
  }
  hardened = {
    name = "nsg-my-spoke-app-uks-001"
    security_rules = [/* ... */]
  }
}

route_tables = {
  default = {
    name                          = "rt-my-spoke-uks-001"
    bgp_route_propagation_enabled = false
    routes                        = []
    tags                          = {}
  }
}
```

Here, the **keys** are `default` and `hardened` (for NSGs) and `default` (for RTs).

### 2) Subnets refer to those keys

```hcl
subnets = {
  mgmt = {
    name                       = "snet-my-spoke-mgmt-uks-001"
    address_prefixes           = ["10.200.10.0/24"]
    network_security_group_key = "default"   # <— references the NSG map key
    route_table_key            = "default"   # <— references the RT map key
    service_endpoints          = []
  }

  app = {
    name                       = "snet-my-spoke-app-uks-001"
    address_prefixes           = ["10.200.11.0/24"]
    network_security_group_key = "hardened"  # <— references the other NSG key
    route_table_key            = null        # or omit to skip RT association
  }
}
```

> If you **rename a map key**, the association will move; if you **rename the _name_ inside the object** (e.g., `nsg-my-spoke-mgmt-...`) Terraform will attempt to **replace** that Azure resource. Plan such changes carefully.

---

## 🚀 Quick start (two connectivity modes)

### A) **vWAN / vHub** connectivity

```hcl
# Look up vHub
data "azurerm_virtual_hub" "primary" {
  provider            = azurerm.connectivity
  name                = "vhub-evri-shared-hub-prod-uks-001"
  resource_group_name = "rg-evri-shared-hub-prod-uks-network-001"
}

module "spoke_network_primary" {
  source = "../_modules/spoke_network"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  location       = "uksouth"
  location_short = "uks"
  common_tags    = var.tags

  resource_group_name = "rg-evri-shared-management-prod-uks-network-001"

  virtual_network_settings = {
    name          = "vnet-evri-shared-management-prod-uks-001"
    address_space = ["10.200.10.0/24"]

    # Optional per‑spoke vWAN overrides
    # vwan_connection_settings = {
    #   internet_security_enabled  = true
    #   associated_route_table_id  = "/subscriptions/.../providers/Microsoft.Network/virtualHubs/routeTables/<rt-name>"
    #   propagated_route_labels    = ["default"]
    # }
  }

  subnets = {
    mgmt = {
      name                       = "snet-evri-shared-management-prod-uks-001"
      address_prefixes           = ["10.200.10.0/24"]
      network_security_group_key = "default"
      route_table_key            = "default"
      service_endpoints          = []
    }
  }

  network_security_groups = {
    default = {
      name           = "nsg-snet-evri-shared-management-prod-uks-001"
      security_rules = []
      tags           = {}
    }
  }

  route_tables = {
    default = {
      name                          = "rt-evri-shared-management-prod-uks-001"
      bgp_route_propagation_enabled = false
      routes                        = []
      tags                          = {}
    }
  }

  common_routes = []

  # ---- Connectivity selection ----
  hub_mode       = "vwan"
  virtual_hub_id = data.azurerm_virtual_hub.primary.id

  # Optional DNS auto-registration
  autoregistration_private_dns_zone_name                = null
  autoregistration_private_dns_zone_resource_group_name = null
}
```

### B) **Hub VNet peering** (with reverse peering)

```hcl
# Look up hub VNet
data "azurerm_virtual_network" "hub" {
  provider            = azurerm.connectivity
  name                = "vnet-hub-prod-uks-001"
  resource_group_name = "rg-hub-prod-uks-network-001"
}

module "spoke_network_primary" {
  source = "../_modules/spoke_network"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  # ... (same as above for location/rg/vnet/subnets/nsgs/rts) ...

  hub_mode                = "hubvnet"
  hub_vnet_id             = data.azurerm_virtual_network.hub.id
  hub_resource_group_name = "rg-hub-prod-uks-network-001"

  # Defaults allow forward on spoke->hub; reverse peering created by default
  # Tweak behavior via virtual_network_settings.peer_to_hub_settings { ... }
}
```

---

## 🧩 Input reference (from `variables.tf`)

### Top-level

| Name                  | Type          | Default | Description                                      |
| --------------------- | ------------- | ------- | ------------------------------------------------ |
| `location`            | `string`      | —       | Azure region for resources.                      |
| `location_short`      | `string`      | —       | Short code used in names (e.g., `uks`).          |
| `common_tags`         | `map(string)` | `{}`    | Tags merged into all resources.                  |
| `resource_group_name` | `string`      | —       | **Existing** RG where all resources are created. |

### VNet (object `virtual_network_settings`)

| Field                      | Type           | Default | Notes                                             |
| -------------------------- | -------------- | ------- | ------------------------------------------------- |
| `name`                     | `string`       | —       | VNet name.                                        |
| `address_space`            | `list(string)` | —       | CIDRs for the spoke VNet.                         |
| `dns_servers`              | `list(string)` | `[]`    | Optional custom DNS.                              |
| `flow_timeout_in_minutes`  | `number`       | `null`  | Optional flow timeout.                            |
| `tags`                     | `map(string)`  | `{}`    | Per‑VNet tags, merged with `common_tags`.         |
| `ddos_protection_plan_id`  | `string`       | `null`  | Optional DDoS plan ID.                            |
| `enable_ddos_protection`   | `bool`         | `false` | Toggle DDoS plan.                                 |
| `peer_to_hub`              | `bool`         | `true`  | Whether to connect to hub (for both modes).       |
| `peer_to_hub_settings`     | `object`       | `{}`    | Hub‑VNet peering flags including reverse peering. |
| `vwan_connection_settings` | `object`       | `{}`    | vHub connection flags/route tables.               |

### Subnets (map `subnets` — **keys are logical IDs**)

Each value:
| Field | Type | Default | Notes |
|---|---|---|---|
| `name` | `string` | — | Azure subnet name. |
| `address_prefixes` | `list(string)` | — | CIDRs for the subnet. |
| `network_security_group_key` | `string` | `null` | **Key** into `network_security_groups` map. |
| `route_table_key` | `string` | `null` | **Key** into `route_tables` map. |
| `delegation` | `list(object)` | `[]` | Optional delegations. |
| `service_endpoints` | `list(string)` | `[]` | Optional service endpoints. |
| `private_endpoint_network_policies` | `string` | `"Enabled"` | `"Enabled"` \| `"Disabled"`. |
| `private_link_service_network_policies_enabled` | `string` | `"Enabled"` | `"Enabled"` \| `"Disabled"`. |
| `default_outbound_access_enabled` | `bool` | `false` | For future parity. |

### NSGs (map `network_security_groups` — **keys are referenced by subnets**)

Each value:
| Field | Type | Default |
|---|---|---|
| `name` | `string` | — |
| `security_rules` | `list(object)` | `[]` |
| `tags` | `map(string)` | `{}` |

### Route Tables (map `route_tables` — **keys are referenced by subnets**)

Each value:
| Field | Type | Default |
|---|---|---|
| `name` | `string` | — |
| `bgp_route_propagation_enabled` | `bool` | `false` |
| `routes` | `list(object)` | `[]` |
| `tags` | `map(string)` | `{}` |

### Common routes

| Name            | Type        | Default | Description                                                                  |
| --------------- | ----------- | ------- | ---------------------------------------------------------------------------- |
| `common_routes` | `list(any)` | `[]`    | Routes automatically **added to every** route table in this module instance. |

### Hub connectivity & DNS

| Name                                                    | Type     | Default     | Description                                          |
| ------------------------------------------------------- | -------- | ----------- | ---------------------------------------------------- |
| `hub_mode`                                              | `string` | `"hubvnet"` | `"hubvnet"` (peering) or `"vwan"` (vHub connection). |
| `virtual_hub_id`                                        | `string` | `null`      | Required when `hub_mode="vwan"`.                     |
| `hub_vnet_id`                                           | `string` | `null`      | Required when `hub_mode="hubvnet"`.                  |
| `hub_resource_group_name`                               | `string` | `null`      | Required for reverse peering in hubvnet mode.        |
| `autoregistration_private_dns_zone_name`                | `string` | `null`      | Optional Private DNS zone name for auto‑reg.         |
| `autoregistration_private_dns_zone_resource_group_name` | `string` | `null`      | RG of that zone.                                     |

---

## 🧾 Outputs (from `outputs.tf`)

| Name                         | Description                                       |
| ---------------------------- | ------------------------------------------------- |
| `virtual_network_id`         | ID of the virtual network.                        |
| `virtual_network_name`       | Name of the virtual network.                      |
| `subnet_ids`                 | Map `logical_key → subnet id`.                    |
| `subnet_names`               | Map `logical_key → subnet name`.                  |
| `network_security_group_ids` | Map `logical_key → NSG id`.                       |
| `route_table_ids`            | Map `logical_key → route table id`.               |
| `peering_spoke_to_hub_id`    | ID of spoke→hub peering (hubvnet). May be `null`. |
| `peering_hub_to_spoke_id`    | ID of hub→spoke peering (hubvnet). May be `null`. |
| `vwan_connection_id`         | ID of vHub connection (vwan). May be `null`.      |

---

## 🔐 Governance & ops notes

- **Keys vs. names**: Subnets bind to NSG/RT **keys**. Changing a key changes the association; changing the **name** within an object may recreate the Azure resource. Plan such changes during maintenance windows.
- **Reverse peering**: Created with the `azurerm.connectivity` provider. Ensure credentials have rights in the **hub** subscription/tenant.
- **AzAPI subnets**: The module ignores changes to `ipConfigurations` and `privateEndpoints` to avoid churn when services attach NICs/PEs.
- **Common routes**: Added to every route table (useful for standard egress to firewall).
- **CIDR overlaps**: Not checked by this module; validate centrally.

---

## 📁 Module layout

```
spoke_network/
├─ main.tf
├─ variables.tf
├─ outputs.tf
└─ (no NAT/diagnostics files in this module)
```

---

## 🧪 Example variable set (vWAN)

```hcl
spoke_network_config_primary = {
  resource_group_name = "rg-evri-shared-management-prod-uks-network-001"
  virtual_network_settings = {
    name          = "vnet-evri-shared-management-prod-uks-001"
    address_space = ["10.200.10.0/24"]
  }
  subnets = {
    mgmt = {
      name                       = "snet-evri-shared-management-prod-uks-001"
      address_prefixes           = ["10.200.10.0/24"]
      network_security_group_key = "default"
      route_table_key            = "default"
      service_endpoints          = []
    }
  }
  network_security_groups = {
    default = {
      name           = "nsg-snet-evri-shared-management-prod-uks-001"
      security_rules = []
      tags           = {}
    }
  }
  route_tables = {
    default = {
      name                          = "rt-evri-shared-management-prod-uks-001"
      bgp_route_propagation_enabled = false
      routes                        = []
      tags                          = {}
    }
  }
  common_routes = []
}
```

---

## ⚠️ Breaking changes to watch for

- Renaming `subnets` / `network_security_groups` / `route_tables` **keys** will appear as destroy/create for associations.
- Switching `hub_mode` changes the connectivity primitive (peering ↔ vHub connection).
- Changing hub peering flags can trigger peering updates on both sides; coordinate with hub owners.

---

## 🙋 Support

Open an issue with your platform/network team. Include: module version, Terraform version, plan/apply output, and the exact variables used.
