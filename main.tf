terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# configure the aws provider
provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscodeaws"
  region                   = "us-west-2"
}

# create vpc
resource "aws_vpc" "main-vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.resource_tags
}

# create internet gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = var.resource_tags
}

# create public subnet  
resource "aws_subnet" "pub-subnet-1" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.pub_subnet_cidr_blocks[0]
  availability_zone = var.availability_zones[0]

  tags = var.resource_tags
}

resource "aws_subnet" "pub-subnet-2" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.pub_subnet_cidr_blocks[1]
  availability_zone = var.availability_zones[1]

  tags = var.resource_tags
}

# create route table
resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = var.resource_tags
}

# create route table association
resource "aws_route_table_association" "pub-subnet-1-rt-assoc" {
  subnet_id      = aws_subnet.pub-subnet-1.id
  route_table_id = aws_route_table.main-rt.id
}

resource "aws_route_table_association" "pub-subnet-2-rt-assoc" {
  subnet_id      = aws_subnet.pub-subnet-2.id
  route_table_id = aws_route_table.main-rt.id
}

# Security group for our production web server
resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allow traffic from the internet
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allow traffic from the internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # allow all traffic to the internet
  }

  tags = var.resource_tags
}

# create t2.micro ec2 instance for development web server in us-west-2a
resource "aws_instance" "prd-web-server" {
  ami                         = var.instance_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pub-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  key_name                    = var.key_name
  availability_zone           = "us-west-2a"
  associate_public_ip_address = true

  user_data = file("${path.module}/simpleWeb.sh")
  tags      = var.resource_tags
}


# create target group
resource "aws_lb_target_group" "main-tg" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-vpc.id

  tags = var.resource_tags
}

# create load balancer
resource "aws_lb" "main-lb" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.pub-subnet-1.id, aws_subnet.pub-subnet-2.id]

  tags = var.resource_tags
}


resource "aws_launch_template" "example" {
  name_prefix = "example-launch-template"

  # Instance type, AMI, and other configurations
  instance_type = "t2.micro"

  # You can also define an AMI ID. For example:
  image_id = var.instance_ami

  # Key pair for SSH access
  key_name = "best_dir" # Replace with your key pair name

  # Network interfaces and security groups
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web-sg.id]
    subnet_id                   = aws_subnet.pub-subnet-2.id

  }



  # User Data (optional)
  user_data = base64encode("#!/bin/bash\nyum update -y")
}

# launch ec2 instance using launch template
resource "aws_instance" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

