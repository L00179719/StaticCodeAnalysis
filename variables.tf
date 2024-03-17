#############################  Variables  #################################

variable "region" {
  default = "us-east-1"
}

variable "environment_name" {
  description = "Define environment_name for resources"
  type        = string
  default     = "code-analysis"
}

variable "vpc_cidr_block" {
  description = "Define cidr block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_name" {
  description = "Define container name"
  type        = string
  default     = "Code Analysis"
}


variable "ubuntu-ami" {
  description = "us-east-1 ubuntu AMI"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

