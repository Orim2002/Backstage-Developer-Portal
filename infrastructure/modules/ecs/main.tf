resource "aws_ecr_repository" "backstage" {
  name                 = "${var.environment}-backstage"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-backstage-cluster"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name = "${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        var.db_password_secret_arn,
        var.github_token_secret_arn,
        var.auth_github_client_id_arn,
        var.auth_github_client_secret_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group
resource "aws_security_group" "ecs" {
  name   = "${var.environment}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 7007
    to_port         = 7007
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Task Definition
resource "aws_ecs_task_definition" "backstage" {
  family                   = "${var.environment}-backstage"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backstage"
      image = "${aws_ecr_repository.backstage.repository_url}:latest"
      
      portMappings = [
        { containerPort = 7007 },
        { containerPort = 3000 }
      ]

      environment = [
        { name = "POSTGRES_HOST",     value = var.db_endpoint },
        { name = "POSTGRES_PORT",     value = "5432" },
        { name = "POSTGRES_USER",     value = var.db_username },
        { name = "POSTGRES_DB",       value = var.db_name },
        { name = "APP_CONFIG_backend_baseUrl", value = var.backstage_base_url },
        { name = "NODE_TLS_REJECT_UNAUTHORIZED", value = "0" }
      ]

      secrets = [
        { name = "POSTGRES_PASSWORD", valueFrom = var.db_password_secret_arn },
        { name = "GITHUB_TOKEN",      valueFrom = var.github_token_secret_arn },
        { name = "AUTH_GITHUB_CLIENT_ID",      valueFrom = var.auth_github_client_id_arn },
        { name = "AUTH_GITHUB_CLIENT_SECRET",      valueFrom = var.auth_github_client_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}-backstage"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "backstage" {
  name            = "${var.environment}-backstage"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backstage.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_app_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backstage"
    container_port   = 7007
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "backstage" {
  name              = "/ecs/${var.environment}-backstage"
  retention_in_days = 30
}