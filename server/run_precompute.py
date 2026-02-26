import asyncio

from app.core.database import init_db
from app.core.logging import configure_logging, get_logger
from app.workers.precompute_worker import run_precompute_once

configure_logging()
logger = get_logger(__name__)


async def main():
    logger.info("Starting precompute worker run...")
    await init_db()
    await run_precompute_once()
    logger.info("Precompute worker run finished")


if __name__ == "__main__":
    asyncio.run(main())
