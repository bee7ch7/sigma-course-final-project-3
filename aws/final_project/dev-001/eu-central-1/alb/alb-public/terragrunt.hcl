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
  source = "github.com/terraform-aws-modules/terraform-aws-alb?ref=v8.2.1//."
}

dependency "vpc" {
  config_path                             = find_in_parent_folders("vpc")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id          = "vpc_id"
    vpc_subnets_ids = ["private_subnet_ids"]
  }
}


dependency "alb_sg" {
  config_path                             = find_in_parent_folders("security_groups/alb")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    security_group_id = "security_group_id"
  }
}

inputs = {

  name = "${local.env_name}-${local.project}-alb"

  vpc_id          = dependency.vpc.outputs.vpc_id
  subnets         = dependency.vpc.outputs.vpc_subnets_ids
  security_groups = [dependency.alb_sg.outputs.security_group_id]

  idle_timeout = 180

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.env_name}-${local.project}-tg-0"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/readme.html"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 5
        timeout             = 15
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  //   tags = local.tags
}