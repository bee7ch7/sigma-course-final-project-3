include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  env      = include.root.inputs.env
  env_name = include.root.inputs.env_name
  project  = include.root.inputs.project
}

terraform {
  source = "git::https://github.com/bee7ch7/terraform-modules.git//aws/aws_ssm_ps"
}

dependency "rds" {
  config_path                             = find_in_parent_folders("rds/mariadb-001")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    db_instance_address = "db_instance_address"
  }
}

inputs = {
  parameters = {
    wordpress_db_url = {
      name        = "/${local.env_name}/wordpress_db/url"
      description = "MariaDB db url"
      type        = "SecureString"
      value       = dependency.rds.outputs.db_instance_address
    }
  }
}
