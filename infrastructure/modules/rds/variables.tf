variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}