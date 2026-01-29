locals {
  # 1) Encode entire config map to a single string
  config_json = tostring(jsonencode(var.config))

  # 2) Apply replacements — templatestring requires a direct reference (local.config_json)
  config_tmpl = templatestring(local.config_json, var.replacements)

  # 3) Unquote arrays/bools that were passed as strings
  config_final_json = replace(
    replace(
      replace(
        replace(local.config_tmpl, "\"[", "["),
        "]\"", "]"
      ),
      "\"true\"", "true"
    ),
    "\"false\"", "false"
  )

  # 4) Decode back to an object
  rendered = jsondecode(local.config_final_json)
}