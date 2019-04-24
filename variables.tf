variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_cidr" {}
variable "subnet_cidrs" {
    type = "map"
}
data "aws_availability_zones" "available" {}
variable "mypublicip" {}
variable "EC2_ami" {}
variable "EC2_type" {}
variable "public_key" {}
variable "private_key" {}