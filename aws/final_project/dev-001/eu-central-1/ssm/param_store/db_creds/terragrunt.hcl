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
inputs = {
  parameters = {
    wordpress_db_password = {
      name        = "/${local.env_name}/wordpress_db/password"
      description = "MariaDB db password"
      type        = "SecureString"
      random      = true
      // value       = "" 
    }
    wordpress_db_user = {
      name        = "/${local.env_name}/wordpress_db/user"
      description = "MariaDB db user"
      type        = "SecureString"
      value       = "admin"
    }
    wordpress_db_name = {
      name        = "/${local.env_name}/wordpress_db/name"
      description = "MariaDB db name"
      type        = "SecureString"
      value       = "wordpress"
    }
  }
}
