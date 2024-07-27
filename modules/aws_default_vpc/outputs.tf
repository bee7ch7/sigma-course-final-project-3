output "vpc_id" {
  value = data.aws_vpc.default[0].id
}

output "vpc_cidr_block" {
  value = data.aws_vpc.default[0].cidr_block
}

output "vpc_subnets_ids" {
  value = data.aws_subnets.default[0].ids
}

output "ami_id" {
  value = data.aws_ami.ami.id
}
