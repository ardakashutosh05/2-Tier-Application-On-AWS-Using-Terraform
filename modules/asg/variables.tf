// Variables expected by the root module when calling module "asg"
variable "project_name" {
  type        = string
  description = "Project name passed from root module"
}

variable "key_name" {
  type        = string
  description = "Key pair name for EC2 instances"
}

variable "client_sg_id" {
  type        = string
  description = "Security group id for client/application access"
}

variable "pri_sub_3a_id" {
  type        = string
  description = "Private subnet 3a ID"
}

variable "pri_sub_4b_id" {
  type        = string
  description = "Private subnet 4b ID"
}

variable "tg_arn" {
  type        = string
  description = "Target group ARN from ALB"
}
