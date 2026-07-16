"""Start custom Meet bot without relying on Hermes's in-memory plugin namespace."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parent
    package_name = "hermes_custom_google_meet"
    spec = importlib.util.spec_from_file_location(
        package_name,
        root / "__init__.py",
        submodule_search_locations=[str(root)],
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load custom Google Meet plugin")
    package = importlib.util.module_from_spec(spec)
    sys.modules[package_name] = package
    spec.loader.exec_module(package)
    from hermes_custom_google_meet.meet_bot import run_bot

    return run_bot()


if __name__ == "__main__":
    raise SystemExit(main())
