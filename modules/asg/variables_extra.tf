// Additional variables for asg module
variable "ami" {
  type        = string
  description = "AMI id for launch template"
  default     = ""
}

variable "cpu" {
  type        = string
  description = "Instance type for launch template"
  default     = "t2.micro"
}

variable "max_size" {
  type        = number
  description = "ASG max size"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "ASG min size"
  default     = 1
}

variable "desired_cap" {
  type        = number
  description = "ASG desired capacity"
  default     = 1
}

variable "asg_health_check_type" {
  type        = string
  description = "ASG health check type (EC2 or ELB)"
  default     = "EC2"
}
