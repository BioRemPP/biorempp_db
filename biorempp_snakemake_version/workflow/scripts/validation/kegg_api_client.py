#!/usr/bin/env python3

import csv
import os
import random
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

from common_normalization import is_na_like, load_na_markers

NA_MARKERS = load_na_markers()

PATTERNS = {
    "ko": re.compile(r"(?:ko:)?(K\d{5})", re.IGNORECASE),
    "cpd": re.compile(r"(?:cpd:)?(C\d{5})", re.IGNORECASE),
    "reaction": re.compile(r"(?:rn:)?(R\d{5})", re.IGNORECASE),
    "ec": re.compile(r"(?:ec:)?((?:\d+\.){3}[0-9A-Za-z\-]+)", re.IGNORECASE),
}


def normalize_token(value, token_type):
    if is_na_like(value, NA_MARKERS):
        return None
    text = str(value).strip()
    match = PATTERNS[token_type].search(text)
    if not match:
        return None
    token = match.group(1)
    if token_type in {"ko", "cpd", "reaction"}:
        return token.upper()
    return token


def read_int_env(name, default, min_value=1):
    raw = os.getenv(name, str(default))
    try:
        value = int(raw)
    except ValueError:
        return default
    return value if value >= min_value else default


def read_float_env(name, default, min_value=0.0):
    raw = os.getenv(name, str(default))
    try:
        value = float(raw)
    except ValueError:
        return default
    return value if value >= min_value else default


RETRY_MAX = read_int_env("BIOREMPP_API_MAX_RETRIES", 6, min_value=1)
REQUEST_TIMEOUT = read_int_env("BIOREMPP_API_TIMEOUT_SECONDS", 90, min_value=1)
BACKOFF_BASE = read_float_env("BIOREMPP_API_BACKOFF_BASE_SECONDS", 1.0, min_value=0.1)
BACKOFF_MAX = read_float_env("BIOREMPP_API_BACKOFF_MAX_SECONDS", 30.0, min_value=0.1)
BACKOFF_JITTER = read_float_env("BIOREMPP_API_BACKOFF_JITTER_RATIO", 0.25, min_value=0.0)


def compute_backoff_seconds(attempt):
    exponential = BACKOFF_BASE * (2 ** (attempt - 1))
    capped = min(BACKOFF_MAX, exponential)
    jitter_multiplier = random.uniform(1 - BACKOFF_JITTER, 1 + BACKOFF_JITTER)
    return max(0.1, capped * jitter_multiplier)


def fetch_text(base_url, endpoint, max_retries=RETRY_MAX, timeout=REQUEST_TIMEOUT):
    url = base_url.rstrip("/") + "/" + endpoint.lstrip("/")
    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            with urllib.request.urlopen(url, timeout=timeout) as response:
                return response.read().decode("utf-8", errors="replace"), url
        except (urllib.error.URLError, TimeoutError) as err:
            last_error = err
            if attempt < max_retries:
                sleep_seconds = compute_backoff_seconds(attempt)
                print(
                    f"[WARN] Fetch failed for {url} at attempt {attempt}/{max_retries} "
                    f"({err}). Retrying in {sleep_seconds:.2f}s."
                )
                time.sleep(sleep_seconds)
    raise RuntimeError(f"Failed to fetch endpoint after {max_retries} attempts: {url} | {last_error}")


def read_link_cache(cache_path):
    """Read a cached KEGG link payload written by cache_kegg_links.py.
    Returns (text, source_path) matching the fetch_text signature."""
    path = Path(cache_path)
    return path.read_text(encoding="utf-8"), str(path)


def parse_link_payload(payload, left_type, right_type, max_invalid_ratio=0.0):
    pairs = set()
    stats = {
        "total_lines": 0,
        "parsed_pairs": 0,
        "swapped_orientation_lines": 0,
        "invalid_lines": 0,
        "invalid_ratio": 0.0,
    }

    for raw_line in payload.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        stats["total_lines"] += 1
        parts = line.split("\t")
        if len(parts) < 2:
            stats["invalid_lines"] += 1
            continue

        col1 = parts[0].strip()
        col2 = parts[1].strip()

        direct_left = normalize_token(col1, left_type)
        direct_right = normalize_token(col2, right_type)
        swap_left = normalize_token(col2, left_type)
        swap_right = normalize_token(col1, right_type)

        direct_valid = direct_left is not None and direct_right is not None
        swap_valid = swap_left is not None and swap_right is not None

        if direct_valid:
            pairs.add((direct_left, direct_right))
            stats["parsed_pairs"] += 1
        elif swap_valid:
            pairs.add((swap_left, swap_right))
            stats["parsed_pairs"] += 1
            stats["swapped_orientation_lines"] += 1
        else:
            stats["invalid_lines"] += 1

    if stats["parsed_pairs"] == 0:
        raise RuntimeError(f"No valid pairs parsed for relation {left_type}->{right_type}")
    if stats["invalid_lines"] > 0:
        invalid_ratio = stats["invalid_lines"] / stats["total_lines"]
        stats["invalid_ratio"] = round(invalid_ratio, 6)
        if invalid_ratio > max_invalid_ratio:
            raise RuntimeError(
                f"Invalid line ratio {invalid_ratio:.4f} exceeds threshold "
                f"{max_invalid_ratio} for {left_type}->{right_type}: "
                f"{stats['invalid_lines']} of {stats['total_lines']} lines"
            )
        print(
            f"[WARNING] parse_link_payload: {stats['invalid_lines']} invalid lines "
            f"({invalid_ratio:.4f}) within tolerance {max_invalid_ratio} "
            f"for {left_type}->{right_type} -- continuing"
        )

    return pairs, stats


def load_database_rows(csv_path, csv_delimiter):
    rows = []
    with open(csv_path, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=csv_delimiter)
        required = {"cpd", "ko", "ec", "reaction"}
        missing = [col for col in required if col not in reader.fieldnames]
        if missing:
            raise RuntimeError(f"Missing required DB columns: {missing}")

        for idx, raw in enumerate(reader, start=2):
            cpd = normalize_token(raw.get("cpd"), "cpd")
            ko = normalize_token(raw.get("ko"), "ko")
            if cpd is None or ko is None:
                continue
            rows.append(
                {
                    "row_number": idx,
                    "cpd": cpd,
                    "ko": ko,
                    "ec": normalize_token(raw.get("ec"), "ec"),
                    "reaction": normalize_token(raw.get("reaction"), "reaction"),
                    "referenceAG": (raw.get("referenceAG") or "").strip(),
                }
            )
    return rows
