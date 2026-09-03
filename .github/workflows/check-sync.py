#!/usr/bin/env python3
"""Check that registry.json and each plugin's manifest.json have matching metadata."""

import json
import sys

SYNC_FIELDS = ["author", "description", "tags", "version", "minNoctaliaVersion"]


def load_json(path):
    with open(path) as f:
        return json.load(f)


def main():
    registry = load_json("registry.json")
    errors = []

    for plugin_entry in registry["plugins"]:
        plugin_id = plugin_entry["id"]
        manifest_path = f"{plugin_id}/manifest.json"

        try:
            manifest = load_json(manifest_path)
        except FileNotFoundError:
            errors.append(f"{plugin_id}: manifest.json not found at {manifest_path}")
            continue

        for field in SYNC_FIELDS:
            reg_val = plugin_entry.get(field)
            man_val = manifest.get(field)
            if reg_val != man_val:
                errors.append(
                    f"{plugin_id}: '{field}' mismatch — "
                    f"registry={reg_val!r}, manifest={man_val!r}"
                )

    if errors:
        print("Manifest sync errors:")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)

    print("All manifests are in sync with registry.json")


if __name__ == "__main__":
    main()
