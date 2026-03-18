###############################################################################
# One-time imports - remove this file after successful apply
###############################################################################

# AudioCodes NLE cross-region routes on hub firewall route tables
# These routes were created manually in Azure and need importing into state.

import {
  to = module.hub_and_spoke_vnet[0].module.hub_and_spoke_vnet.azurerm_route.firewall_mesh["AudioCodesNLEWest"]
  id = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-uks-001/providers/Microsoft.Network/routeTables/rt-hub-prod-fw-uks-001/routes/AudioCodesNLEWest"
}

import {
  to = module.hub_and_spoke_vnet[0].module.hub_and_spoke_vnet.azurerm_route.firewall_mesh["AudioCodesSBCNLEWest"]
  id = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-uks-001/providers/Microsoft.Network/routeTables/rt-hub-prod-fw-uks-001/routes/AudioCodesSBCNLEWest"
}

import {
  to = module.hub_and_spoke_vnet[0].module.hub_and_spoke_vnet.azurerm_route.firewall_mesh["AudioCodesNLESouth"]
  id = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-ukw-001/providers/Microsoft.Network/routeTables/rt-hub-prod-fw-ukw-001/routes/AudioCodesNLESouth"
}

import {
  to = module.hub_and_spoke_vnet[0].module.hub_and_spoke_vnet.azurerm_route.firewall_mesh["AudioCodesSBCNLESouth"]
  id = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-ukw-001/providers/Microsoft.Network/routeTables/rt-hub-prod-fw-ukw-001/routes/AudioCodesSBCNLESouth"
}
