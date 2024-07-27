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
  source = "git::https://github.com/bee7ch7/terraform-modules.git//aws/aws_security_groups?ref=v1.0.7"
}

dependency "vpc" {
  config_path                             = find_in_parent_folders("vpc")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id          = "vpc_id"
    vpc_subnets_ids = ["private_subnet_ids"]
  }
}

inputs = {
  name        = "${local.env_name}-${local.project}-${basename(get_terragrunt_dir())}-sg"
  description = "Allow access from anywhere"
  vpc_id      = dependency.vpc.outputs.vpc_id
  ports_in = [
    {
      protocol         = "tcp"
      from_port        = "80",
      to_port          = "80",
      cidr_blocks      = [],
      ipv6_cidr_blocks = [],
      security_groups  = []
    },
    {
      protocol         = "tcp"
      from_port        = "443",
      to_port          = "443",
      cidr_blocks      = [],
      ipv6_cidr_blocks = [],
      security_groups  = []
    }
  ],

  # egress
  ports_out = {
    cidr_blocks      = [],
    ipv6_cidr_blocks = []
  }

}
