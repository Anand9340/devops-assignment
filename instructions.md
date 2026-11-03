
# Developer Instructions – Notifier Application

## 1. Project Overview

This project demonstrates an asynchronous notification processing application using:

- FastAPI – REST API backend
- Celery – Background task processing
- Redis – Message broker and result backend
- Nginx – Frontend hosting and API reverse proxy
- Docker – Containerization
- Docker Compose – Local multi-container orchestration

## 2. Prerequisites

Install the following tools:

| Tool | Purpose |
|---|---|
| Git | Source code management |
| Docker | Container runtime |
| Docker Compose v2 | Multi-container orchestration |
| Linux / macOS / Windows with WSL2 | Development environment |

Verify installations:

```bash
git --version
docker --version
docker compose version
```

## 3. Clone the Repository

```bash
git clone https://github.com/Anand9340/devops-assignment.git
cd devops-assignment
```

## 4. Configure Environment Variables

Create the local environment file:

```bash
cp .env.example .env
```

Default configuration:

| Variable | Description | Default |
|---|---|---|
| REDIS_URL | Redis connection URL | redis://redis:6379/0 |
| TASK_DELAY_SECONDS | Simulated task processing delay | 10 |

For local Docker Compose, use the service hostname `redis` in the Redis URL.

Do not commit `.env` or production credentials to GitHub.

## 5. Build Docker Images

Build the application images:

```bash
docker compose build
```

Check the generated images:

```bash
docker images
```

## 6. Start the Application

Start all services in detached mode:

```bash
docker compose up -d --build --wait
```

Check container status:

```bash
docker compose ps
```

Expected services:

- frontend
- backend
- worker
- redis

## 7. Access the Application

Open the frontend:

```text
http://localhost:8080
```

Backend health endpoint:

```text
http://localhost:8080/health
```

The Nginx frontend proxies API requests to the FastAPI backend.

## 8. Test the Application

Run the automated smoke test:

```bash
chmod +x scripts/smoke_test.sh

./scripts/smoke_test.sh http://localhost:8080
```

The smoke test:

1. Checks the application health endpoint.
2. Sends a notification request.
3. Retrieves the generated task ID.
4. Polls the task-status endpoint.
5. Confirms successful task completion.

## 9. Useful API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/health` | Application health check |
| POST | `/notify/?email=user@example.com` | Submit a background task |
| GET | `/task_status/{task_id}` | Retrieve task status and result |

Example request:

```bash
curl -X POST \
  "http://localhost:8080/notify/?email=user@example.com"
```

Example task status request:

```bash
curl http://localhost:8080/task_status/TASK_ID
```

Replace `TASK_ID` with the ID returned by the notification request.

## 10. View Logs and Troubleshoot

View all service logs:

```bash
docker compose logs
```

Follow logs continuously:

```bash
docker compose logs -f
```

Backend logs:

```bash
docker compose logs -f backend
```

Worker logs:

```bash
docker compose logs -f worker
```

Redis logs:

```bash
docker compose logs -f redis
```

Frontend logs:

```bash
docker compose logs -f frontend
```

Inspect running containers:

```bash
docker compose ps
```

Inspect a container:

```bash
docker inspect <container_name>
```

## 11. Restart Services

Restart all services:

```bash
docker compose restart
```

Rebuild and restart:

```bash
docker compose up -d --build
```

## 12. Stop the Application

Stop containers while preserving named volumes:

```bash
docker compose down
```

Stop containers and remove Compose-managed volumes:

```bash
docker compose down -v
```

**Warning:** The `-v` option deletes the Compose-managed Redis data volume, if one exists.

## 13. Project Structure

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
│   └── Terraform configuration files
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

## 14. Important Notes

- The local Redis service runs as a Docker container.
- The frontend uses Nginx to serve the static HTML page and proxy API requests.
- Celery processes tasks asynchronously.
- The application currently simulates notification processing; it does not send real emails.
- Production AWS resources are managed separately through Terraform.
- Never commit AWS credentials, GitHub tokens, `.env` files, Terraform state, or generated Terraform plans.
