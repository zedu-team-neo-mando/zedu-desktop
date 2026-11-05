#!/usr/bin/env python3
"""Exa web search for agents and maintainers working in zedu-desktop.

Calls Exa's search endpoint through the official `exa-py` SDK and prints the top
matches with relevance highlights, so an agent can pull current web results
(Flutter/Dart answers, package release notes, API docs) without leaving the repo.

Usage:
    EXA_API_KEY=... python3 scripts/exa_search.py "flutter tray_manager linux" -n 5
    python3 scripts/exa_search.py "flutter desktop window_manager" --json

Install the SDK once (outside the app's Flutter toolchain):
    python3 -m pip install exa-py

The key is read from the EXA_API_KEY environment variable only and is never
printed. Get one at https://dashboard.exa.ai.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

try:
    from exa_py import Exa
except ImportError:  # pragma: no cover - depends on the caller's environment
    sys.exit("exa-py is not installed. Run: python3 -m pip install exa-py")

DEFAULT_NUM_RESULTS = 5


class MissingApiKeyError(RuntimeError):
    """Raised when EXA_API_KEY is absent from the environment."""


def build_client() -> Exa:
    """Return an Exa client authenticated with EXA_API_KEY."""
    api_key = os.environ.get("EXA_API_KEY", "").strip()
    if not api_key:
        raise MissingApiKeyError(
            "EXA_API_KEY is not set. Export it in your shell (see .env.example) "
            "before running an Exa search."
        )
    return Exa(api_key)


def _as_dict(result: Any) -> dict[str, Any]:
    return {
        "title": getattr(result, "title", None),
        "url": getattr(result, "url", None),
        "published_date": getattr(result, "published_date", None),
        "highlights": list(getattr(result, "highlights", None) or []),
    }


def search_web(query: str, num_results: int = DEFAULT_NUM_RESULTS) -> list[dict[str, Any]]:
    """Search the web with Exa and return highlights for each relevant page."""
    response = build_client().search(
        query,
        num_results=num_results,
        contents={"highlights": True},
    )
    return [_as_dict(result) for result in response.results]


def _print_text(results: list[dict[str, Any]]) -> None:
    if not results:
        print("No results.")
        return
    for index, result in enumerate(results, start=1):
        print(f"{index}. {result['title'] or '(untitled)'}")
        print(f"   {result['url']}")
        if result["published_date"]:
            print(f"   published: {result['published_date']}")
        for highlight in result["highlights"]:
            print(f"   - {highlight.strip()}")
        print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Search the web with the Exa SDK.")
    parser.add_argument("query", nargs="+", help="search query")
    parser.add_argument(
        "-n",
        "--num-results",
        type=int,
        default=DEFAULT_NUM_RESULTS,
        help=f"number of results to return (default: {DEFAULT_NUM_RESULTS})",
    )
    parser.add_argument("--json", action="store_true", help="print raw JSON instead of text")
    args = parser.parse_args()

    try:
        results = search_web(" ".join(args.query), num_results=args.num_results)
    except MissingApiKeyError as error:
        print(error, file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        _print_text(results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
