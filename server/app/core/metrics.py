from __future__ import annotations

from collections import defaultdict
from threading import Lock


class MetricsRegistry:
    def __init__(self):
        self._lock = Lock()
        self._request_total = defaultdict(int)
        self._request_latency_ms = defaultdict(float)
        self._app_event_total = defaultdict(int)

    def observe(self, method: str, path: str, status_code: int, latency_ms: float) -> None:
        key = (method.upper(), path, str(status_code))
        with self._lock:
            self._request_total[key] += 1
            self._request_latency_ms[key] += latency_ms

    def increment_app_event(self, event: str, labels: dict[str, str] | None = None) -> None:
        normalized_labels = tuple(
            sorted((labels or {}).items(), key=lambda item: item[0]),
        )
        key = (event, normalized_labels)
        with self._lock:
            self._app_event_total[key] += 1

    def render_prometheus(self) -> str:
        lines = [
            "# HELP omnisource_http_requests_total Total HTTP requests",
            "# TYPE omnisource_http_requests_total counter",
        ]
        for (method, path, status), value in self._request_total.items():
            lines.append(
                f'omnisource_http_requests_total{{method="{method}",path="{path}",status="{status}"}} {value}'
            )

        lines.extend(
            [
                "# HELP omnisource_http_request_latency_ms_sum Accumulated request latency in ms",
                "# TYPE omnisource_http_request_latency_ms_sum counter",
            ]
        )
        for (method, path, status), value in self._request_latency_ms.items():
            lines.append(
                f'omnisource_http_request_latency_ms_sum{{method="{method}",path="{path}",status="{status}"}} {value:.3f}'
            )

        lines.extend(
            [
                "# HELP omnisource_app_events_total Application-level event counters",
                "# TYPE omnisource_app_events_total counter",
            ]
        )
        for (event, labels), value in self._app_event_total.items():
            label_parts = [f'event="{event}"']
            label_parts.extend([f'{key}="{val}"' for key, val in labels])
            joined = ",".join(label_parts)
            lines.append(f"omnisource_app_events_total{{{joined}}} {value}")
        return "\n".join(lines) + "\n"


metrics_registry = MetricsRegistry()
