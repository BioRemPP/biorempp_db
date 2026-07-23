#!/usr/bin/env python3

from pathlib import Path


DEFAULT_NA_MARKERS = {"", "NA", "NAN", "<NA>", "NONE", "NULL", "N/A"}
NA_MARKERS_FILE = Path("workflow/lib/na_markers.txt")


def load_na_markers(path=NA_MARKERS_FILE):
    markers = {m.upper() for m in DEFAULT_NA_MARKERS}
    file_path = Path(path)
    if not file_path.exists():
        return markers

    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        markers.add(line.upper())
    return markers


def is_na_like(value, na_markers):
    if value is None:
        return True
    text = str(value).strip()
    return text == "" or text.upper() in na_markers
