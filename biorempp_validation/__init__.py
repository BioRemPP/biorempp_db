"""Compatibility shim for running `python -m biorempp_validation.run_validation` from repo root."""

from pathlib import Path

_PACKAGE_DIR = Path(__file__).resolve().parent
_SRC_PACKAGE_DIR = _PACKAGE_DIR / "src" / "biorempp_validation"

if _SRC_PACKAGE_DIR.exists():
    __path__.append(str(_SRC_PACKAGE_DIR))  # type: ignore[name-defined]
