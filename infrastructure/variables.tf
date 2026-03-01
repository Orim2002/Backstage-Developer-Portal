variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "db_username" {
  type    = string
  default = "backstage"
}

variable "db_password" {
  type      = string
  sensitive = true
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

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "backstage_base_url" {
  type = string
}