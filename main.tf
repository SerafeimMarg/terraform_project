terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# AWS Provider Congifuration
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# VPC
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr

  tags = var.environment_tags
}

# SUBNET_PUBLIC
resource "aws_subnet" "subnet_public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]

  tags = var.environment_tags
}

# INTERNET_GATEWAY
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
}

# ROUTE FOR VPC ACCESS
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

# NAT GATEWAY FOR VPC RESOURCES
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.subnet_public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

# LB SECURITY GROUP
resource "aws_security_group" "lb-sg" {
  name   = "test-elb-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SECURITY_GROUP
resource "aws_security_group" "sg-test-instance" {
  name   = "test_instance_sg"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.environment_tags
}

# ELB
resource "aws_elb" "test_elb" {
  name            = "test-elb"
  security_groups = [aws_security_group.lb-sg.id]
  subnets         = aws_subnet.subnet_public.*.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = var.environment_tags
}

# AUTOSCALING_GROUP TEMPLATE
resource "aws_launch_template" "test_instance" {
  name_prefix            = "test-instance"
  image_id               = data.aws_ami.packer_ami.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg-test-instance.id]

  key_name = aws_key_pair.generated_key.key_name

  lifecycle {
    create_before_destroy = true
  }
}

# PRIVATE KEY ALGO
resource "tls_private_key" "algorithm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# KEY PAIR
resource "aws_key_pair" "generated_key" {
  key_name   = "tf-key"
  public_key = tls_private_key.algorithm.public_key_openssh
}

# TF_KEY.PEM TO USE FOR SSH
resource "local_file" "id_rsa_file" {
  content  = tls_private_key.algorithm.private_key_pem
  filename = "${path.module}/tf_key.pem"
}

# AUTOSCALING_GROUP
resource "aws_autoscaling_group" "test_instance" {
  name                = "test-asg"
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = aws_subnet.subnet_public.*.id

  launch_template {
    id      = aws_launch_template.test_instance.id
    version = "$Latest"
  }

  tag {
    key                 = "env"
    value               = "dev"
    propagate_at_launch = true
  }
}

# ASG and ELB AUTOSCALING ATTACHMENT
resource "aws_autoscaling_attachment" "test_instance" {
  autoscaling_group_name = aws_autoscaling_group.test_instance.id
  elb                    = aws_elb.test_elb.id
}

# # //////////////////////////////
# # DATA
# # //////////////////////////////

data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_ami" "packer_ami" {
  most_recent = true
  name_regex  = "^Debian11-NginX-"
  owners      = ["self"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}