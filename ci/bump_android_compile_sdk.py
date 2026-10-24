#!/usr/bin/env python3
"""Raise Godot 4.6's bundled Android compileSdk so targetSdk 36 is valid."""

import re
import sys
import zipfile
from pathlib import Path


def main() -> int:
    archive = Path(sys.argv[1])
    if not archive.is_file():
        print(f"missing {archive}", file=sys.stderr)
        return 1
    temporary = archive.with_suffix(".zip.tmp")
    changed = False
    with zipfile.ZipFile(archive, "r") as source, zipfile.ZipFile(temporary, "w") as dest:
        for info in source.infolist():
            data = source.read(info.filename)
            if info.filename.endswith("config.gradle"):
                text = data.decode("utf-8")
                updated, compile_count = re.subn(r"compileSdk\s*:\s*35", "compileSdk         : 36", text, count=1)
                updated, target_count = re.subn(r"targetSdk\s*:\s*35", "targetSdk          : 36", updated, count=1)
                if compile_count != 1:
                    print(f"no compileSdk pin found in {info.filename}", file=sys.stderr)
                    return 1
                if target_count != 1:
                    print(f"compileSdk patched but targetSdk pin was missing in {info.filename}")
                data = updated.encode("utf-8")
                changed = True
                print(f"patched {info.filename}")
            dest.writestr(info, data)
    if not changed:
        print("android source zip has no config.gradle", file=sys.stderr)
        return 1
    temporary.replace(archive)
    return 0


if __name__ == "__main__":
    sys.exit(main())
