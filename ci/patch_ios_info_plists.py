#!/usr/bin/env python3
"""Set the build number and export-compliance flag on the exported app plist."""

import plistlib
import sys
from pathlib import Path


def main() -> int:
    root = Path(sys.argv[1])
    bundle_id = sys.argv[2]
    version = sys.argv[3]
    build = sys.argv[4]
    patched = 0
    for path in root.rglob("*.plist"):
        try:
            info = plistlib.loads(path.read_bytes())
        except Exception:
            continue
        if not isinstance(info, dict):
            continue
        package_type = str(info.get("CFBundlePackageType", ""))
        if package_type == "FMWK":
            continue
        identifier = str(info.get("CFBundleIdentifier", ""))
        # Godot's Xcode project often leaves the id as an Xcode variable.
        uses_bundle = bundle_id in identifier or identifier.startswith("$(PRODUCT_BUNDLE_IDENTIFIER")
        named_app = "Cobblewick" in str(info.get("CFBundleDisplayName", "")) + str(info.get("CFBundleName", ""))
        if not uses_bundle and not named_app:
            print(f"skip {path} identifier={identifier!r}")
            continue
        info["CFBundleShortVersionString"] = version
        info["CFBundleVersion"] = build
        info["ITSAppUsesNonExemptEncryption"] = False
        info["CFBundleDisplayName"] = "Cobblewick"
        path.write_bytes(plistlib.dumps(info, fmt=plistlib.FMT_XML))
        print(f"patched {path}")
        patched += 1
    if patched == 0:
        print("no app Info.plist contained the bundle id", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
