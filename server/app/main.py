import time
from uuid import uuid4
import asyncio

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.database import init_db
from app.core.redis import redis_client
from app.core.logging import configure_logging, get_logger
from app.core.metrics import metrics_registry
from app.ml.vectorizer import get_vectorizer
from app.api.routers import actions, auth, content, recommendations, research, user

configure_logging()
logger = get_logger(__name__)

app = FastAPI(title=settings.PROJECT_NAME)


async def _warmup_vectorizer() -> None:
    try:
        await asyncio.to_thread(get_vectorizer().get_embedding, "startup warmup")
        logger.info("Vectorizer warmup completed")
    except Exception as exc:
        logger.warning("Vectorizer warmup failed: %s", type(exc).__name__)


@app.on_event("startup")
async def startup_event():
    logger.info("Starting %s", settings.PROJECT_NAME)
    await init_db()
    redis_ok = await redis_client.ping()
    logger.info("Redis health: %s", "up" if redis_ok else "down")
    asyncio.create_task(_warmup_vectorizer())


@app.on_event("shutdown")
async def shutdown_event():
    await asyncio.gather(
        content.service.close(),
        content.ml_engine.close(),
        research.engine.close(),
        return_exceptions=True,
    )
    await redis_client.close()
    logger.info("Shutdown completed")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_context_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or str(uuid4())
    request.state.request_id = request_id
    start = time.perf_counter()

    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
    except Exception:
        duration_ms = (time.perf_counter() - start) * 1000
        metrics_registry.observe(
            request.method,
            request.url.path,
            status,
            duration_ms,
        )
        logger.exception(
            "request_failed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status": status,
                "duration_ms": round(duration_ms, 2),
            },
        )
        raise

    duration_ms = (time.perf_counter() - start) * 1000
    metrics_registry.observe(
        request.method,
        request.url.path,
        status,
        duration_ms,
    )
    response.headers["x-request-id"] = request_id

    log_extra = {
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
        "status": status,
        "duration_ms": round(duration_ms, 2),
    }
    if request.method == "OPTIONS":
        logger.debug("request_completed", extra=log_extra)
    else:
        logger.info("request_completed", extra=log_extra)
        if duration_ms >= settings.SLOW_REQUEST_THRESHOLD_MS:
            logger.warning("request_slow", extra=log_extra)
    return response


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", str(uuid4()))
    logger.exception(
        "unhandled_exception",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
        },
    )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "request_id": request_id,
        },
    )

# routs
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(content.router)
app.include_router(actions.router)
app.include_router(recommendations.router)
app.include_router(research.router)

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "project": settings.PROJECT_NAME,
        "redis": "up" if await redis_client.ping() else "down",
    }


@app.get("/metrics")
async def metrics():
    return Response(
        content=metrics_registry.render_prometheus(),
        media_type="text/plain; version=0.0.4",
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
