##################################################
# GENERAL
##################################################
variable "project" {
  type = string
  description = "The project name"
}

variable "env" {
  type = string
  description = "The environment to deploy the VPC into"
}

variable "region" {
  type = string
  description = "The region to deploy the VPC into"
}

##################################################
# NETWORK
##################################################

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "num_zones" {
  description = "The number of availability zones to use"
  type        = number
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway"
  type        = bool
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT gateways"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames"
  type        = bool
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support"
  type        = bool
}

variable "one_nat_gateway_per_az" {
  description = "Whether to enable one NAT gateway per availability zone"
  type        = bool
}

variable "public_subnet_tags" {
  description = "The tags for the public subnets"
  type        = map(string)
}

variable "private_subnet_tags" {
  description = "The tags for the private subnets"
  type        = map(string)
}

variable "vpc_tags" {
  description = "The tags for the VPC"
  type        = map(string)
}
