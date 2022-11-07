variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-west-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "environment_tags" {
  type = map(string)
  default = {
    env = "dev"
  }
}