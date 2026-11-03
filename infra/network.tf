# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

# -----------------------------
# Availability Zones
# -----------------------------

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    public_1 = {
      cidr = "10.0.1.0/24"
      az   = local.azs[0]
    }
    public_2 = {
      cidr = "10.0.2.0/24"
      az   = local.azs[1]
    }
  }

  private_subnets = {
    private_1 = {
      cidr = "10.0.11.0/24"
      az   = local.azs[0]
    }
    private_2 = {
      cidr = "10.0.12.0/24"
      az   = local.azs[1]
    }
  }
}

# -----------------------------
# Public Subnets
# -----------------------------

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${each.key}"
  }
}

# -----------------------------
# Private Subnets
# -----------------------------

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project}-${each.key}"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-igw"
  }
}

# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# Private Route Table
# No Internet Route / No NAT
# -----------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
# ALB Security Group
# -----------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allow HTTP traffic from CloudFront"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from CloudFront origin-facing prefix list"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    prefix_list_ids = [
      data.aws_ec2_managed_prefix_list.cloudfront_origin.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

# -----------------------------
# CloudFront Managed Prefix List
# -----------------------------

data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# -----------------------------
# ECS Security Group
# -----------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.project}-ecs-sg"
  description = "Allow application traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Backend traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ecs-sg"
  }
}

# -----------------------------
# Redis Security Group
# -----------------------------

resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg"
  description = "Allow Redis traffic only from ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis TLS traffic from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-redis-sg"
  }
}
