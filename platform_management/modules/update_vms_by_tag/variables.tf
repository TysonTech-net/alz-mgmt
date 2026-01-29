variable "resource_group_name" {
  type        = string
  description = "Name of the RG that will hold the Maintenance Configurations."
}

variable "location" {
  type        = string
  description = "Azure region for the Maintenance Configurations (and used for assignment MI location)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to resources. (MCs get PatchGroup tag from each item.)"
}

variable "maintenance_configurations" {
  description = <<EOT
Map of maintenance configurations to create. Key becomes the MC name.
Fields:
  tag                     = string
  recur_every             = string  (e.g. "Month Second Saturday")
  start_date_time         = string  (e.g. "2025-01-01 01:00")
  duration                = string  (e.g. "03:55")
  time_zone               = string  (e.g. "UTC")
  reboot                  = string  (e.g. "IfRequired")
  windows_classifications = list(string)
  linux_classifications   = list(string)
EOT
  type = map(object({
    tag                     = string
    recur_every             = string
    start_date_time         = string
    duration                = string
    time_zone               = string
    reboot                  = string
    windows_classifications = list(string)
    linux_classifications   = list(string)
  }))
}

variable "management_group_id" {
  type        = string
  description = "Management Group resource ID where the initiative is created and assigned (e.g. /providers/Microsoft.Management/managementGroups/<mgName>)."

  validation {
    condition     = can(regex("^/providers/Microsoft.Management/managementGroups/[^/]+$", var.management_group_id))
    error_message = "management_group_id must be a valid MG resource ID."
  }
}

variable "policy_assignment_location" {
  type        = string
  description = "Azure region for the assignment's managed identity (required for DeployIfNotExists)."
}

variable "policy_initiative_name" {
  type        = string
  default     = "Update-VMs-by-Tag"
  description = "Resource name for the custom initiative (unique within the MG)."
}

variable "policy_initiative_display_name" {
  type    = string
  default = "Update VMs based on Patch Group Tag"
}

variable "policy_assignment_display_name" {
  type    = string
  default = "Update VMs based on Patch Group Tag"
}

variable "policy_initiative_description" {
  type    = string
  default = "Custom initiative referencing built-in policies to enforce VM updates based on Patch Group tag using Maintenance Configurations."
}

variable "tag_key" {
  type        = string
  default     = "PatchGroup"
  description = "Tag key used by the built-in policy to select VMs."
}

variable "grant_contributor_to_assignment_mi" {
  type        = bool
  default     = true
  description = "Grant Contributor on the MG scope to the assignment's managed identity (helps remediation)."
}
