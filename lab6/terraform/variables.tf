variable "aws_region" {
  description = "AWS region for Lab 6"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of web instances"
  type        = number
  default     = 2
}
