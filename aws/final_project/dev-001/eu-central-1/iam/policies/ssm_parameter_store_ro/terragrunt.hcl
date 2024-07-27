include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=v5.34.0"
}

locals {
  env_name   = include.root.inputs.env_name
  env        = include.root.inputs.env
  project    = include.root.inputs.project
  region     = include.root.inputs.region
  account_id = include.root.inputs.account_id
  tags       = include.root.inputs.tags
}

inputs = {
  name = "${local.env_name}-${local.project}-read-ssm-params"

  description = "Allow get SSM parameters"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameter*",
              "ssm:GetParameterHistory",
              "ssm:DescribeParameters"
            ],
            "Resource": [
              "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${local.env_name}/*"
            ]
        }
    ]
}
EOF

  tags = local.tags
}
