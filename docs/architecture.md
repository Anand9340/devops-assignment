
# System Architecture

## 1. Application Overview

The Notifier application accepts notification requests through a web interface, processes them asynchronously using Celery, and uses Redis as its message broker and result backend.

## 2. Local Development Architecture

```mermaid
flowchart TB
    U["User / Web Browser"]

    subgraph LOCAL["Local Docker Compose Environment"]
        N["Nginx Frontend<br/>Port 8080"]
        F["FastAPI Backend<br/>Port 8000"]
        R[("Redis 7<br/>Broker and Result Backend")]
        W["Celery Worker<br/>Concurrency: 2"]
    end

    U --> N
    N -->|"API requests"| F
    F -->|"Enqueue task"| R
    R -->|"Task message"| W
    W -->|"Store task result"| R
    F -->|"Poll task status"| R
    F -->|"API response"| N
    N --> U
```

## 3. AWS Cloud Architecture

```mermaid
flowchart TB
    U["User / Browser"]
    CF["Amazon CloudFront"]
    S3[("Amazon S3<br/>Frontend Hosting")]
    ALB["Application Load Balancer"]
    ECS["Amazon ECS Fargate"]
    API["Backend Service<br/>FastAPI"]
    WORKER["Worker Service<br/>Celery"]
    REDIS[("Amazon ElastiCache<br/>Redis")]
    ECR[("Amazon ECR")]
    SM["AWS Secrets Manager"]
    CW["Amazon CloudWatch"]
    SNS["Amazon SNS"]

    U --> CF
    CF --> S3
    CF --> ALB
    ALB --> API
    API --> REDIS
    WORKER --> REDIS
    ECR -.-> ECS
    SM -.-> API
    SM -.-> WORKER
    API --> CW
    WORKER --> CW
    CW --> SNS
```

## 4. Infrastructure Provisioning and CI/CD

```mermaid
flowchart LR
    DEV["Developer"]
    GIT["GitHub Repository"]
    CI["GitHub Actions CI"]
    CD["GitHub Actions Deploy"]
    TF["Terraform"]
    AWS["AWS Infrastructure"]
    ECR["Amazon ECR"]
    ECS["Amazon ECS"]
    S3["Frontend S3"]
    CF["CloudFront"]

    DEV --> GIT
    GIT --> CI
    GIT --> CD
    CD --> TF
    TF --> AWS
    CD --> ECR
    ECR --> ECS
    CD --> S3
    S3 --> CF
```

## 5. Main AWS Components

| Component | Purpose |
|---|---|
| Amazon VPC | Network isolation |
| Public and private subnets | Network segmentation |
| Application Load Balancer | Routes API traffic |
| Amazon ECS Fargate | Runs backend and worker containers |
| Amazon ECR | Stores Docker images |
| Amazon ElastiCache Redis | Managed message broker and result backend |
| AWS Secrets Manager | Stores Redis connection credentials |
| Amazon S3 | Hosts frontend files |
| Amazon CloudFront | Delivers frontend and API traffic |
| Amazon CloudWatch | Logs and monitoring |
| Amazon SNS | Notifications from monitoring |
| Terraform | Infrastructure as Code |
| GitHub Actions | CI/CD automation |

## 6. Application Request Flow

1. User opens the frontend through CloudFront.
2. Frontend sends a notification request to the API.
3. CloudFront forwards API traffic through the Application Load Balancer.
4. FastAPI receives the request and submits a Celery task.
5. Redis stores the task message.
6. Celery worker processes the task.
7. Worker stores the task result in Redis.
8. Frontend polls the task-status endpoint.
9. FastAPI retrieves the task status and returns it to the frontend.

**Note:** The current application simulates notification processing. It does not send real emails.
