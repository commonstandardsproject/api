"""HTTP client used by the contract tests.

Tests target whatever backend is at ``CSP_BASE_URL``. The stdlib is enough; we
avoid third-party deps so the suite can run in any environment.
"""

from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Mapping


DEFAULT_LIVE_URL = "https://api.commonstandardsproject.com"


@dataclass
class Response:
    status: int
    headers: Mapping[str, str]
    body: bytes

    @property
    def text(self) -> str:
        return self.body.decode("utf-8", errors="replace")

    def json(self) -> Any:
        return json.loads(self.body) if self.body else None


class Client:
    def __init__(self, base_url: str | None = None, api_key: str | None = None):
        self.base_url = (base_url or os.environ.get("CSP_BASE_URL") or DEFAULT_LIVE_URL).rstrip("/")
        self.api_key = api_key if api_key is not None else os.environ.get("CSP_API_KEY")

    def request(
        self,
        method: str,
        path: str,
        *,
        params: Mapping[str, Any] | None = None,
        json_body: Any = None,
        form_body: Mapping[str, Any] | None = None,
        headers: Mapping[str, str] | None = None,
        api_key: str | None | object = ...,  # sentinel: leave default
    ) -> Response:
        url = self.base_url + path
        if params:
            query = urllib.parse.urlencode({k: _qval(v) for k, v in params.items()})
            url = f"{url}?{query}"

        all_headers = {"Accept": "application/json"}

        if api_key is ...:
            key = self.api_key
        else:
            key = api_key
        if key is not None:
            all_headers["Api-Key"] = key

        data: bytes | None = None
        if json_body is not None:
            data = json.dumps(json_body).encode("utf-8")
            all_headers["Content-Type"] = "application/json"
        elif form_body is not None:
            data = urllib.parse.urlencode(form_body).encode("utf-8")
            all_headers["Content-Type"] = "application/x-www-form-urlencoded"

        if headers:
            all_headers.update(headers)

        req = urllib.request.Request(url, data=data, method=method, headers=all_headers)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return Response(
                    status=resp.status,
                    headers={k: v for k, v in resp.headers.items()},
                    body=resp.read(),
                )
        except urllib.error.HTTPError as exc:
            return Response(
                status=exc.code,
                headers={k: v for k, v in exc.headers.items()} if exc.headers else {},
                body=exc.read() if exc.fp else b"",
            )

    def get(self, path: str, **kwargs) -> Response:
        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs) -> Response:
        return self.request("POST", path, **kwargs)


def _qval(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    return str(v)


def allow_writes() -> bool:
    return os.environ.get("CSP_ALLOW_WRITES", "").lower() in ("1", "true", "yes")
