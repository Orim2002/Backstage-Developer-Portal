output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_username" {
  value = aws_db_instance.main.username
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}