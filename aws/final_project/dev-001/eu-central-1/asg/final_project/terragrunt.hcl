include "root" {
  path   = find_in_parent_folders()
  expose = true
}


locals {
  env_name = include.root.inputs.env_name
  project  = include.root.inputs.project


  user_data = <<-EOF
  #!/bin/bash

  sudo yum update -y
  sudo yum install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -a -G docker ec2-user

  sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  mkdir -p /app/final

  export DB_PASSWORD=$(aws ssm get-parameter --name "/${local.env_name}/wordpress_db/password" --with-decryption --query "Parameter.Value" --output text)
  export DB_USERNAME=$(aws ssm get-parameter --name "/${local.env_name}/wordpress_db/user" --with-decryption --query "Parameter.Value" --output text)
  export DB_URL=$(aws ssm get-parameter --name "/${local.env_name}/wordpress_db/url" --with-decryption --query "Parameter.Value" --output text)
  export DB_NAME=$(aws ssm get-parameter --name "/${local.env_name}/wordpress_db/name" --with-decryption --query "Parameter.Value" --output text)

  docker run -d \
    --name wordpress \
    -p 80:80 \
    --restart always \
    -e WORDPRESS_DB_HOST=$DB_URL \
    -e WORDPRESS_DB_USER=$DB_USERNAME \
    -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD \
    -e WORDPRESS_DB_NAME=$DB_NAME \
    wordpress:latest

  EOF
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-autoscaling?ref=v6.5.3//."
}


dependency "ssm_policy" {
  config_path                             = find_in_parent_folders("iam/policies/ssm_parameter_store_ro")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    arn = "arn:aws:iam::012345678912:policy/xxx"
  }
}
dependency "security_groups" {
  config_path                             = find_in_parent_folders("security_groups/asg")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    security_group_id = "sg-xxx"
  }
}

dependency "vpc" {
  config_path                             = find_in_parent_folders("vpc")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    vpc_id          = "vpc_id"
    vpc_subnets_ids = ["private_subnet_ids"]
    ami_id          = "ami_id"
  }
}

dependency "alb_tg" {
  config_path                             = find_in_parent_folders("alb/alb-public")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs = {
    target_group_arns = ["arn"]
  }
}

dependency "db_url" {
  config_path                             = find_in_parent_folders("ssm/param_store/db_url")
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info", "show"]
  mock_outputs                            = {}
}


inputs = {
  name                            = "${local.env_name}-${local.project}-asg"
  use_name_prefix                 = false
  launch_template_use_name_prefix = false
  image_id                        = dependency.vpc.outputs.ami_id
  instance_type                   = "t3.micro"

  security_groups                 = [dependency.security_groups.outputs.security_group_id]
  user_data                       = base64encode(local.user_data)
  ignore_desired_capacity_changes = true
  key_name                        = "meldm"

  target_group_arns = dependency.alb_tg.outputs.target_group_arns

  create_iam_instance_profile = true
  iam_role_name               = "${local.env_name}-${local.project}-asg"
  iam_role_description        = "ASG role for get SSM parameters"
  iam_role_policies = {
    AWSParameterStoreAccess = dependency.ssm_policy.outputs.arn
  }

  vpc_zone_identifier = dependency.vpc.outputs.vpc_subnets_ids
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

}