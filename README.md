
# Notifier – End-to-End DevOps Project

<p align="center">
  <strong>Containerization | AWS | Terraform | CI/CD | Monitoring</strong>
</p>

## Project Overview

Notifier is an asynchronous notification-processing application built using FastAPI, Celery and Redis.

This project demonstrates an end-to-end DevOps implementation, including Docker containerization, local orchestration with Docker Compose, AWS infrastructure provisioning using Terraform, and CI/CD automation using GitHub Actions.

The application accepts notification requests, processes them asynchronously through Celery workers, and exposes task status through REST APIs.

**Note:** Notification processing is simulated. Actual email delivery is not implemented.

## Architecture

The application runs locally using Docker Compose and is deployed on AWS using managed cloud services.

See the detailed diagrams:

[View System Architecture](docs/architecture.md)

## Technology Stack

| Category | Technologies |
|---|---|
| Backend | Python, FastAPI |
| Background Processing | Celery |
| Message Broker | Redis |
| Frontend | HTML, JavaScript |
| Web Server | Nginx |
| Containerization | Docker |
| Local Orchestration | Docker Compose |
| Cloud Platform | AWS |
| Container Registry | Amazon ECR |
| Container Platform | Amazon ECS Fargate |
| Managed Redis | Amazon ElastiCache |
| Object Storage | Amazon S3 |
| Content Delivery | Amazon CloudFront |
| Infrastructure as Code | Terraform |
| CI/CD | GitHub Actions |
| Monitoring | Amazon CloudWatch |
| Notifications | Amazon SNS |

## Application Workflow

1. User opens the frontend.
2. User submits a notification request.
3. FastAPI receives the request.
4. Celery submits the background task through Redis.
5. Celery worker processes the task.
6. Redis stores the task result.
7. Frontend polls the API for task status.
8. User sees the task completion result.

## Project Structure

```text
devops-assignment/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── backend/
│   ├── Dockerfile
│   ├── main.py
│   ├── worker.py
│   └── requirements.txt
├── docs/
│   └── architecture.md
├── frontend/
│   └── index.html
├── infra/
│   ├── bootstrap/
│   └── Terraform files
├── nginx/
│   └── default.conf
├── scripts/
│   └── smoke_test.sh
├── .env.example
├── docker-compose.yml
├── instructions.md
├── journey.md
└── README.md
```

## Run Locally

### Prerequisites

- Git
- Docker
- Docker Compose v2

### Clone Repository

```bash
git clone https://github.com/Anand9340/devops-assignment.git
cd devops-assignment
```

### Configure Environment

```bash
cp .env.example .env
```

### Build and Start

```bash
docker compose up -d --build --wait
```

### Verify Containers

```bash
docker compose ps
```

### Access Application

Frontend:

http://localhost:8080

Health endpoint:

http://localhost:8080/health

### Run Smoke Test

```bash
chmod +x scripts/smoke_test.sh
./scripts/smoke_test.sh http://localhost:8080
```

### View Logs

```bash
docker compose logs -f
```

### Stop Application

```bash
docker compose down
```

For complete setup and troubleshooting instructions, see [Developer Instructions](instructions.md).

## AWS Deployment

The application infrastructure is provisioned using Terraform.

### AWS Services

- Amazon VPC and subnets
- Application Load Balancer
- Amazon ECS Fargate
- Amazon ECR
- Amazon ElastiCache Redis
- AWS Secrets Manager
- Amazon S3
- Amazon CloudFront
- Amazon CloudWatch
- Amazon SNS
- AWS IAM

### Infrastructure Provisioning

Terraform configuration is maintained in the `infra/` directory.

The Terraform backend uses Amazon S3 for remote state storage and S3 lockfile support for state locking.

### CI/CD Pipeline

GitHub Actions workflows are maintained in:

```text
.github/workflows/
```

**Continuous Integration**

- Docker Compose build and startup.
- Application smoke testing.
- Terraform formatting and validation.

**Continuous Deployment**

- AWS authentication using GitHub OIDC.
- Docker image build and push to ECR.
- Terraform deployment.
- Frontend synchronization to S3.
- CloudFront cache invalidation.
- ECS service verification and application smoke testing.

## Live Deployment

**Frontend URL:** https://d3igdflvatkly.cloudfront.net

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/architecture.md) | Local and AWS architecture diagrams |
| [Developer Instructions](instructions.md) | Local installation and execution guide |
| [Project Journey](journey.md) | Implementation decisions, challenges and learnings |

## Security Practices

- AWS IAM role-based deployment authentication.
- GitHub Actions OIDC integration.
- Redis credentials managed through AWS Secrets Manager.
- Environment-based configuration.
- Terraform state and generated plans excluded from Git.
- Non-root application container user.

## Cost Considerations

The deployed environment uses managed AWS services, which may incur charges based on usage and account credits.

A NAT Gateway was omitted to reduce fixed infrastructure costs. ECS tasks use public IP addresses, which may incur public IPv4 charges.

Review AWS billing and resource usage regularly.

## Key Learning Outcomes

- Docker image creation and containerization.
- Docker Compose orchestration.
- FastAPI and Celery integration.
- Redis-based asynchronous processing.
- AWS ECS Fargate and ECR.
- Terraform infrastructure provisioning.
- Remote state management.
- GitHub Actions CI/CD.
- AWS IAM and OIDC authentication.
- CloudWatch monitoring and logging.

---

**Project:** Notifier – End-to-End DevOps Implementation
**Repository:** https://github.com/Anand9340/devops-assignment
