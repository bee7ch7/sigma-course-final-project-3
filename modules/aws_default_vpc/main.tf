data "aws_vpc" "default" {
  count = var.default_vpc ? 1 : 0

  default = true
}

data "aws_subnets" "default" {
  count = var.default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_ami" "ami" {
  most_recent = true
  filter {
    name = "name"
    # values = ["*ubuntu*24*-amd64-server-*"]
    values = ["al2023-ami-2023*x86_64*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["137112412989"]
}
