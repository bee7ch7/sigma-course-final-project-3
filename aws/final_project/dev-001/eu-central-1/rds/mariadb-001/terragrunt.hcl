include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.8.0"
}

locals {
  env_name   = include.root.inputs.env_name
  env        = include.root.inputs.env
  project    = include.root.inputs.project
  region     = include.root.inputs.region
  account_id = include.root.inputs.account_id
  tags       = include.root.inputs.tags
}

dependency "vpc" {
  config_path                             = find_in_parent_folders("vpc")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id          = "vpc_id"
    vpc_subnets_ids = ["vpc_subnets_ids"]
  }
}

dependency "rds_sg" {
  config_path                             = find_in_parent_folders("security_groups/rds-mariadb")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    security_group_id = "security_group_id"
  }
}

dependency "db_creds" {
  config_path                             = find_in_parent_folders("ssm/param_store/db_creds")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    ssm_parameter_values = {
      wordpress_db_name     = "name"
      wordpress_db_password = "password"
      wordpress_db_user     = "user"
    }
  }
}

inputs = {

  identifier = "${local.env_name}-${local.project}-${basename(get_terragrunt_dir())}"

  publicly_accessible = true

  engine         = "mariadb"
  engine_version = "10.11.6"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 1000

  db_name                     = dependency.db_creds.outputs.ssm_parameter_values.wordpress_db_name
  username                    = dependency.db_creds.outputs.ssm_parameter_values.wordpress_db_user
  password                    = dependency.db_creds.outputs.ssm_parameter_values.wordpress_db_password
  manage_master_user_password = false
  port                        = 3306

  multi_az                        = false
  create_db_subnet_group          = true
  db_subnet_group_use_name_prefix = false
  subnet_ids                      = dependency.vpc.outputs.vpc_subnets_ids
  vpc_security_group_ids          = [dependency.rds_sg.outputs.security_group_id]
  create_db_parameter_group       = false
  create_db_option_group          = false
}