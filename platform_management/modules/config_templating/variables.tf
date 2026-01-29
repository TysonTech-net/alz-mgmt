variable "replacements" {
  description = "Key/value tokens you can reference with $${key} in your tfvars."
  type        = map(string)
  default     = {}
}

# Throw anything in here (maps, lists, objects). Keys become top-level sections.
variable "config" {
  type    = any
  default = {}
}
