locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account_vars.hcl"))
  env          = local.account_vars.locals.env
  env_name     = local.account_vars.locals.env_name
  region       = local.account_vars.locals.region
  domain_name  = local.account_vars.locals.domain_name
  project      = local.account_vars.locals.project
  account_id   = local.account_vars.locals.account_id

  tags = {
    "Project"          = local.project
    "Environment"      = local.env
    "Environment Name" = local.env_name
  }

}

remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket         = "${local.env}-tfstates.sigma-final-project-3"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "final-project-3-terraform-locks"
  }
}

inputs = {
  env         = local.env
  env_name    = local.env_name
  region      = local.region
  domain_name = local.domain_name
  project     = local.project
  account_id  = local.account_id
  tags        = local.tags
}

generate "myconfig" {
  path      = "_config.tf"
  if_exists = "overwrite"

  contents = <<EOF
provider "aws" {
    region = "${local.region}"
}

provider "aws" {
    region = "us-east-1"
    alias  = "acm"
}
EOF
}
