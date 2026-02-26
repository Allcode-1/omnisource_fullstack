from __future__ import annotations

import asyncio
from collections import Counter
from datetime import datetime, timedelta
from typing import Dict, List

from app.core.logging import get_logger
from app.models.content_meta import ContentMetadata
from app.models.interaction import Interaction
from app.models.user import User
from app.ml.vectorizer import get_vectorizer
from app.schemas.analytics import (
    NotificationItem,
    TimelineItem,
    TrackEventRequest,
    UserStats,
)

logger = get_logger(__name__)


class AnalyticsService:
    DEFAULT_WEIGHTS: Dict[str, float] = {
        "view": 0.2,
        "open_detail": 0.5,
        "dwell_time": 0.3,
        "search": 0.1,
        "like": 1.0,
        "playlist_add": 0.8,
    }

    async def track_event(
        self,
        user_id: str,
        payload: TrackEventRequest,
        ranking_variant: str | None = None,
    ):
        weight = payload.weight
        if weight is None:
            weight = self.DEFAULT_WEIGHTS.get(payload.type, 0.1)

        if payload.ext_id and payload.ext_id != "app" and payload.content_type:
            doc = await ContentMetadata.find_one(ContentMetadata.ext_id == payload.ext_id)
            title = str(payload.meta.get("title") or payload.ext_id)
            subtitle = payload.meta.get("subtitle")
            image_url = payload.meta.get("image_url")
            rating = payload.meta.get("rating") or 0.0
            genres = payload.meta.get("genres") or []
            release_date = payload.meta.get("release_date")
            try:
                safe_rating = float(rating)
            except (TypeError, ValueError):
                safe_rating = 0.0

            if doc is None:
                embedding_text = f"{title} {payload.meta.get('description') or ''}"
                vector = await asyncio.to_thread(
                    get_vectorizer().get_embedding,
                    embedding_text,
                )
                await ContentMetadata(
                    ext_id=payload.ext_id,
                    type=payload.content_type,
                    title=title,
                    subtitle=subtitle,
                    image_url=image_url,
                    rating=safe_rating,
                    genres=[str(item) for item in genres if item],
                    release_date=release_date,
                    features_vector=vector,
                ).insert()
            else:
                updated = False
                if not doc.title and title:
                    doc.title = title
                    updated = True
                if not doc.image_url and image_url:
                    doc.image_url = str(image_url)
                    updated = True
                if updated:
                    await doc.save()

        meta = dict(payload.meta)
        if ranking_variant:
            meta.setdefault("ranking_variant", ranking_variant)

        interaction = Interaction(
            user_id=user_id,
            ext_id=payload.ext_id or "app",
            content_type=payload.content_type,
            type=payload.type,
            weight=weight,
            meta=meta,
        )
        await interaction.insert()

        logger.info(
            "Tracked event user=%s type=%s ext_id=%s weight=%.3f",
            user_id,
            payload.type,
            interaction.ext_id,
            weight,
        )

        return {"status": "ok"}

    async def get_timeline(self, user_id: str, limit: int = 50) -> List[TimelineItem]:
        interactions = (
            await Interaction.find(Interaction.user_id == user_id)
            .sort("-created_at")
            .limit(limit)
            .to_list()
        )
        ext_ids = [item.ext_id for item in interactions if item.ext_id and item.ext_id != "app"]
        meta_map: Dict[str, ContentMetadata] = {}
        if ext_ids:
            docs = await ContentMetadata.find({"ext_id": {"$in": ext_ids}}).to_list()
            meta_map = {doc.ext_id: doc for doc in docs}

        timeline: List[TimelineItem] = []
        for item in interactions:
            doc = meta_map.get(item.ext_id)
            timeline.append(
                TimelineItem(
                    id=str(item.id),
                    type=item.type,
                    ext_id=item.ext_id,
                    content_type=item.content_type,
                    weight=item.weight,
                    title=(doc.title if doc else item.meta.get("title")),
                    image_url=(doc.image_url if doc else item.meta.get("image_url")),
                    created_at=item.created_at,
                    meta=item.meta or {},
                )
            )
        return timeline

    async def get_stats(self, user_id: str, days: int = 30) -> UserStats:
        cutoff = datetime.utcnow() - timedelta(days=days)
        interactions = await Interaction.find(
            Interaction.user_id == user_id,
            Interaction.created_at >= cutoff,
        ).to_list()

        counts = Counter(item.type for item in interactions)
        total_events = len(interactions)

        views = counts.get("view", 0)
        opens = counts.get("open_detail", 0)
        likes = counts.get("like", 0)

        dwell_values = [
            item.meta.get("seconds")
            for item in interactions
            if item.type == "dwell_time" and isinstance(item.meta.get("seconds"), (int, float))
        ]
        avg_dwell = round(sum(dwell_values) / len(dwell_values), 2) if dwell_values else 0.0

        content_type_counts = Counter(
            item.content_type for item in interactions if item.content_type
        )

        ab_metrics: Dict[str, Dict[str, float]] = {}
        for variant in ("content_only", "hybrid_ml"):
            variant_events = [
                item
                for item in interactions
                if item.meta.get("ranking_variant") == variant
            ]
            if not variant_events:
                continue
            variant_counts = Counter(item.type for item in variant_events)
            variant_views = variant_counts.get("view", 0)
            variant_opens = variant_counts.get("open_detail", 0)
            variant_likes = variant_counts.get("like", 0)
            ab_metrics[variant] = {
                "events": float(len(variant_events)),
                "ctr": round(variant_opens / variant_views, 4) if variant_views > 0 else 0.0,
                "save_rate": round(variant_likes / variant_opens, 4)
                if variant_opens > 0
                else 0.0,
            }

        ctr = round(opens / views, 4) if views > 0 else 0.0
        save_rate = round(likes / opens, 4) if opens > 0 else 0.0

        return UserStats(
            total_events=total_events,
            counts_by_type=dict(counts),
            ctr=ctr,
            save_rate=save_rate,
            avg_dwell_seconds=avg_dwell,
            top_content_types=dict(content_type_counts),
            ab_metrics=ab_metrics,
        )

    async def get_notifications(self, user: User) -> List[NotificationItem]:
        stats = await self.get_stats(str(user.id), days=14)
        now = datetime.utcnow()
        notifications: List[NotificationItem] = []

        notifications.append(
            NotificationItem(
                id="digest-weekly",
                title="Weekly Digest Ready",
                body=f"You made {stats.total_events} interactions in the last 14 days.",
                level="info",
                created_at=now,
            )
        )

        if stats.counts_by_type.get("like", 0) == 0:
            notifications.append(
                NotificationItem(
                    id="likes-empty",
                    title="Save Content You Enjoy",
                    body="Tap heart on cards to improve your recommendations.",
                    level="warning",
                    created_at=now,
                )
            )

        if user.interests:
            notifications.append(
                NotificationItem(
                    id="interests",
                    title="New Picks For Your Interests",
                    body=f"Try Deep Research for: {', '.join(user.interests[:3])}.",
                    level="success",
                    created_at=now,
                )
            )

        if stats.ctr < 0.2 and stats.counts_by_type.get("view", 0) > 10:
            notifications.append(
                NotificationItem(
                    id="ctr-tip",
                    title="Tune Your Feed",
                    body="Use advanced search filters and like more items you open.",
                    level="warning",
                    created_at=now,
                )
            )

        return notifications
