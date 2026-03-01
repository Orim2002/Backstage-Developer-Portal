resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-backstage-db-subnet"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.environment}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-backstage-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20

  db_name  = "backstage"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = false
  multi_az            = var.environment == "prod" ? true : false

  tags = {
    Environment = var.environment
  }
}