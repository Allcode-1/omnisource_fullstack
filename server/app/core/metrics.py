from __future__ import annotations

from collections import defaultdict
from threading import Lock


class MetricsRegistry:
    def __init__(self):
        self._lock = Lock()
        self._request_total = defaultdict(int)
        self._request_latency_ms = defaultdict(float)

    def observe(self, method: str, path: str, status_code: int, latency_ms: float) -> None:
        key = (method.upper(), path, str(status_code))
        with self._lock:
            self._request_total[key] += 1
            self._request_latency_ms[key] += latency_ms

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
        return "\n".join(lines) + "\n"


metrics_registry = MetricsRegistry()
