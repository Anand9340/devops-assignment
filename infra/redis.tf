
resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

# Redis authentication secret
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${var.project}-redis-auth"
  description             = "Redis authentication token"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

# Redis subnet group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-redis"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

# Redis replication group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project}-redis"
  description          = "Notifier application Redis"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  automatic_failover_enabled = false
  multi_az_enabled           = false

  snapshot_retention_limit = 0
  apply_immediately        = true

  depends_on = [
    aws_secretsmanager_secret_version.redis_auth
  ]

  tags = {
    Name = "${var.project}-redis"
  }
}

# Redis connection URL
locals {
  redis_url = "rediss://:${random_password.redis_auth.result}@${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379/0?ssl_cert_reqs=required"
}

# ECS Redis connection secret
resource "aws_secretsmanager_secret" "redis_connection" {
  name                    = "${var.project}-redis-connection"
  description             = "Redis connection settings for ECS"
  recovery_window_in_days = 7
}

# Store Redis connection variables as JSON
resource "aws_secretsmanager_secret_version" "redis_connection" {
  secret_id = aws_secretsmanager_secret.redis_connection.id

  secret_string = jsonencode({
    REDIS_URL             = local.redis_url
    CELERY_BROKER_URL     = local.redis_url
    CELERY_RESULT_BACKEND = local.redis_url
  })
}

