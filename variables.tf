variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.16.0.0/16"

}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    project     = "my-ec2",
    environment = "dev"
  }
}

variable "pub_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.16.0.0/20", "10.16.16.0/20"]
}

variable "availability_zones" {
  description = "Availability zones for public subnets"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "instance_ami" {
  description = "AMI for the EC2 instance"
  type        = string
  default     = "ami-07d9cf938edb0739b"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = "best_dir"
}
