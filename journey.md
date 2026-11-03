
# Project Journey – Notifier Application

## 1. Project Overview

The objective of this project was to containerize an existing asynchronous notification application, run it locally, provision cloud infrastructure using Infrastructure as Code, and implement an automated CI/CD pipeline.

The application uses FastAPI, Celery and Redis to process background notification tasks.

## 2. Understanding the Application

The application consists of four main components:

| Component | Responsibility |
|---|---|
| Frontend | Provides the user interface to submit notification requests and monitor task status |
| FastAPI | Exposes REST API endpoints |
| Celery Worker | Processes background tasks asynchronously |
| Redis | Acts as the message broker and result backend |

### Application Workflow

1. A user submits an email address through the frontend.
2. FastAPI receives the request through `POST /notify/`.
3. FastAPI submits a background task to Celery.
4. Redis stores the task message.
5. The Celery worker retrieves and processes the task.
6. The worker stores the task result in Redis.
7. The frontend polls `GET /task_status/{task_id}`.
8. FastAPI returns the current task status and result.

**Note:** The application simulates notification processing. Actual email delivery is not implemented.

## 3. Containerization

### Objective

Containerize the application and its dependencies to provide a consistent development and deployment environment.

### Implementation

- Created a Dockerfile for the FastAPI backend and Celery worker.
- Used the same application image for the backend and worker services.
- Configured Redis as a separate container for local development.
- Used Docker Compose to manage all four services.
- Configured Nginx to serve the frontend and proxy API requests.
- Configured health checks and service dependencies.
- Used environment variables instead of hardcoding runtime configuration.

### Result

The complete application can be started with:

```bash
docker compose up -d --build --wait
```

## 4. Local Application Testing

The application was tested using Docker Compose.

Important validation steps:

- Verified that all containers started successfully.
- Checked service health.
- Verified frontend access through Nginx.
- Tested notification submission.
- Verified asynchronous task processing.
- Checked task status and completion.
- Used container logs for troubleshooting.

Automated testing is provided through:

```bash
./scripts/smoke_test.sh http://localhost:8080
```

## 5. Cloud Platform Selection

AWS was selected to deploy the application using managed cloud services.

### AWS Services Used

| AWS Service | Purpose |
|---|---|
| Amazon VPC | Network isolation |
| Public and private subnets | Network segmentation |
| Application Load Balancer | API traffic routing |
| Amazon ECS Fargate | Container execution |
| Amazon ECR | Container image registry |
| Amazon ElastiCache Redis | Managed Redis service |
| AWS Secrets Manager | Secure Redis credentials |
| Amazon S3 | Frontend hosting |
| Amazon CloudFront | Content delivery and API entry point |
| Amazon CloudWatch | Application logs and monitoring |
| Amazon SNS | Monitoring notifications |
| AWS IAM | Access management |

### Why ECS Fargate?

ECS Fargate was selected because it runs containers without requiring the management of EC2 worker nodes.

### Why ElastiCache?

ElastiCache provides a managed Redis service instead of requiring a self-managed Redis container in production.

## 6. Infrastructure as Code with Terraform

Terraform was used to provision AWS infrastructure.

### Implementation

- Configured Terraform providers and versions.
- Created reusable infrastructure configuration files.
- Provisioned networking and security resources.
- Created ECR and ECS resources.
- Provisioned ElastiCache Redis.
- Configured S3 and CloudFront for frontend hosting.
- Configured monitoring resources.
- Configured remote Terraform state using Amazon S3.
- Used Terraform state locking through S3 lockfile support.

A separate bootstrap configuration manages the initial Terraform state infrastructure and deployment prerequisites.

### Benefits

- Repeatable infrastructure provisioning.
- Version-controlled infrastructure.
- Reduced manual configuration.
- Easier infrastructure review and maintenance.

## 7. CI/CD with GitHub Actions

GitHub Actions was selected to automate application validation and deployment.

### Continuous Integration

The CI workflow performs:

1. Repository checkout.
2. Environment preparation.
3. Docker Compose application build.
4. Application startup and health checks.
5. Automated smoke testing.
6. Terraform formatting.
7. Terraform initialization and validation.

### Continuous Deployment

The deployment workflow is designed to:

1. Authenticate to AWS using GitHub Actions OIDC.
2. Build the backend Docker image.
3. Push the image to Amazon ECR using the Git commit SHA as its tag.
4. Run Terraform plan and apply.
5. Synchronize frontend files to Amazon S3.
6. Create a CloudFront invalidation.
7. Verify ECS services.
8. Run an application smoke test.

### Security

AWS authentication uses an IAM role and GitHub Actions OIDC rather than storing long-lived AWS access keys in GitHub secrets.

## 8. Challenges and Solutions

| Challenge | Solution |
|---|---|
| Running backend and worker independently | Used a shared Docker image with separate Compose services |
| Managing asynchronous tasks | Used Redis with Celery |
| Frontend-to-backend communication | Configured Nginx as a reverse proxy |
| Container startup dependencies | Added Redis and backend health checks |
| Cloud infrastructure consistency | Used Terraform |
| Secure AWS authentication | Configured GitHub Actions OIDC |
| Frontend content delivery | Used S3 with CloudFront |
| Production Redis credentials | Used AWS Secrets Manager |
| Terraform state management | Configured S3 remote state and locking |

## 9. Monitoring and Reliability

CloudWatch is used for application logging and monitoring.

SNS is configured for monitoring notifications.

ECS service deployment circuit-breaker settings provide deployment failure detection and rollback behavior.

## 10. Cost and Design Considerations

The infrastructure uses managed services to reduce operational overhead.

A NAT Gateway was omitted to avoid its additional fixed and data-processing costs. ECS tasks use public subnets with public IP addresses, so outbound network access and public IPv4 charges must be considered.

The deployed architecture also uses load balancing, managed Redis, container hosting and CloudFront. These services may incur AWS charges depending on usage and account credits.

## 11. Final Outcome

The project brings together:

- Application containerization.
- Docker Compose orchestration.
- Asynchronous task processing.
- AWS managed services.
- Terraform infrastructure provisioning.
- GitHub Actions CI/CD.
- CloudWatch monitoring.
- CloudFront-based frontend delivery.

The project demonstrates an end-to-end approach to building, containerizing, deploying and managing a cloud-hosted application using DevOps practices.

## 12. Key Learnings

Through this project, I gained practical experience with:

- Dockerfile development and image management.
- Docker Compose networking and health checks.
- FastAPI and Celery integration.
- Redis broker and result-backend configuration.
- AWS ECS Fargate and ECR.
- Terraform remote state management.
- AWS IAM and GitHub OIDC authentication.
- GitHub Actions CI/CD automation.
- S3 and CloudFront integration.
- CloudWatch logging and monitoring.
- Cloud infrastructure cost considerations.
### Fill Complete Journey
