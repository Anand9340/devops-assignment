from fastapi import FastAPI
from celery.result import AsyncResult

from worker import celery, write_log_celery

app = FastAPI()


@app.post("/notify/")
async def notify_user(email: str):

    task = write_log_celery.delay(
        f"Notification sent to {email}"
    )

    return {
        "message": f"Email will be sent to {email}",
        "task_id": task.id
    }


@app.get("/task_status/{task_id}")
async def get_task_status(task_id: str):

    result = AsyncResult(
        task_id,
        app=celery
    )

    if result.failed():
        return {
            "task_id": task_id,
            "status": "failed"
        }

    if result.ready():
        return {
            "task_id": task_id,
            "status": "completed",
            "result": result.result
        }

    return {
        "task_id": task_id,
        "status": "in progress"
    }


@app.get("/health")
async def health_get():

    return {
        "message": "OK"
    }


@app.post("/health/")
async def health():

    return {
        "message": "OK"
    }
