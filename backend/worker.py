import os
import time

from celery import Celery
from celery.utils.log import get_task_logger

REDIS_URL = os.getenv(
    "REDIS_URL",
    "redis://localhost:6379/0"
)

TASK_DELAY_SECONDS = int(
    os.getenv("TASK_DELAY_SECONDS", "10")
)

celery = Celery(
    "worker",
    broker=os.getenv("CELERY_BROKER_URL", REDIS_URL),
    backend=os.getenv("CELERY_RESULT_BACKEND", REDIS_URL),
)

celery.conf.update(
    result_expires=3600,
)

logger = get_task_logger(__name__)


@celery.task
def write_log_celery(message: str):
    time.sleep(TASK_DELAY_SECONDS)

    logger.info("Processing notification: %s", message)

    return f"Task completed: {message}"
