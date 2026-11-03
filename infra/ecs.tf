# ----------------------------------------
# CloudWatch Log Groups
# ----------------------------------------

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project}/backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project}/worker"
  retention_in_days = 7
}

# ----------------------------------------
# ECS IAM Assume Role Policy
# ----------------------------------------

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ----------------------------------------
# ECS Execution Role
# ----------------------------------------

resource "aws_iam_role" "task_execution" {
  name               = "${var.project}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project}-secrets-access"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = [
        aws_secretsmanager_secret.redis_connection.arn
      ]
    }]
  })
}

# ----------------------------------------
# ECS Application Task Role
# ----------------------------------------

resource "aws_iam_role" "task_role" {
  name               = "${var.project}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# ----------------------------------------
# ECS Cluster
# ----------------------------------------

resource "aws_ecs_cluster" "main" {
  name = var.project

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project}-cluster"
  }
}

# ----------------------------------------
# Common Image and Environment
# ----------------------------------------

locals {
  image = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

  common_env = [
    {
      name  = "CORS_ORIGINS"
      value = "https://${aws_cloudfront_distribution.main.domain_name}"
    },
    {
      name  = "TASK_DELAY_SECONDS"
      value = "10"
    }
  ]

  redis_secrets = [
    {
      name      = "REDIS_URL"
      valueFrom = "${aws_secretsmanager_secret.redis_connection.arn}:REDIS_URL::"
    },
    {
      name      = "CELERY_BROKER_URL"
      valueFrom = "${aws_secretsmanager_secret.redis_connection.arn}:CELERY_BROKER_URL::"
    },
    {
      name      = "CELERY_RESULT_BACKEND"
      valueFrom = "${aws_secretsmanager_secret.redis_connection.arn}:CELERY_RESULT_BACKEND::"
    }
  ]
}

# ----------------------------------------
# Backend Task Definition
# ----------------------------------------

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.image
      essential = true

      command = [
        "uvicorn",
        "main:app",
        "--host",
        "0.0.0.0",
        "--port",
        "8000"
      ]

      portMappings = [{
        containerPort = 8000
        hostPort      = 8000
        protocol      = "tcp"
      }]

      environment = local.common_env
      secrets     = local.redis_secrets

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-backend-task"
  }
}

# ----------------------------------------
# Worker Task Definition
# ----------------------------------------

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = local.image
      essential = true

      command = [
        "celery",
        "-A",
        "worker:celery",
        "worker",
        "--loglevel=info",
        "--concurrency=2"
      ]

      environment = local.common_env
      secrets     = local.redis_secrets

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "worker"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project}-worker-task"
  }
}

# ----------------------------------------
# Backend ECS Service
# ----------------------------------------

resource "aws_ecs_service" "backend" {
  name                  = "backend"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.backend.arn
  desired_count         = var.desired_count
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  network_configuration {
    subnets          = [for subnet in aws_subnet.public : subnet.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "backend"
    container_port   = 8000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.task_execution,
    aws_iam_role_policy.secrets_access
  ]
}

# ----------------------------------------
# Worker ECS Service
# ----------------------------------------

resource "aws_ecs_service" "worker" {
  name                  = "worker"
  cluster               = aws_ecs_cluster.main.id
  task_definition       = aws_ecs_task_definition.worker.arn
  desired_count         = 1
  launch_type           = "FARGATE"
  wait_for_steady_state = true

  network_configuration {
    subnets          = [for subnet in aws_subnet.public : subnet.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.task_execution,
    aws_iam_role_policy.secrets_access
  ]
}
