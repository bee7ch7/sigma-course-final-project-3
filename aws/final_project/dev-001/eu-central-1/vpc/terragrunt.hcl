include {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../../modules/aws_default_vpc"
}

inputs = {

  default_vpc = true

}