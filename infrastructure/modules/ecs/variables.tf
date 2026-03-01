variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "frontend_target_group_arn" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_password_secret_arn" {
  type = string
}

variable "github_token_secret_arn" {
  type = string
}

variable "auth_github_client_id_arn" {
  type = string
}

variable "auth_github_client_secret_arn" {
  type = string
}

variable "task_cpu" {
  type    = number
  default = 1024
}

variable "task_memory" {
  type    = number
  default = 2048
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "backstage_base_url" {
  type = string
}