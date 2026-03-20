# Input parameters
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "xpenz"
}