import json
import logging
import asyncio
from datetime import datetime, timezone
from logging.config import dictConfig

from app.core.config import settings


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        for key in ("request_id", "method", "path", "status", "duration_ms"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, ensure_ascii=False)


class SuppressUvicornShutdownNoiseFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        if record.name != "uvicorn.error":
            return True

        message = record.getMessage()
        if (
            "Exception in ASGI application" in message
            and "CancelledError" in message
        ):
            return False
        if "Traceback (most recent call last):" in message and "KeyboardInterrupt" in message:
            return False
        if "asyncio.exceptions.CancelledError" in message and "lifespan" in message:
            return False

        if record.exc_info:
            exc = record.exc_info[1]
            if isinstance(exc, (KeyboardInterrupt, asyncio.CancelledError)):
                return False

        return True


def configure_logging() -> None:
    level = settings.LOG_LEVEL.upper()

    dictConfig(
        {
            "version": 1,
            "disable_existing_loggers": False,
            "filters": {
                "suppress_uvicorn_shutdown_noise": {
                    "()": "app.core.logging.SuppressUvicornShutdownNoiseFilter",
                },
            },
            "formatters": {
                "json": {
                    "()": "app.core.logging.JsonFormatter",
                },
            },
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "formatter": "json",
                    "filters": ["suppress_uvicorn_shutdown_noise"],
                },
            },
            "root": {"level": level, "handlers": ["console"]},
            "loggers": {
                "uvicorn": {"level": level, "handlers": ["console"], "propagate": False},
                "uvicorn.error": {
                    "level": level,
                    "handlers": ["console"],
                    "propagate": False,
                },
                "uvicorn.access": {
                    "level": "WARNING",
                    "handlers": ["console"],
                    "propagate": False,
                },
            },
        }
    )


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
