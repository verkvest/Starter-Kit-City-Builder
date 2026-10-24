#!/usr/bin/env python3
"""Fill Android signing fields and the CI build number in export_presets.cfg."""

import os
from pathlib import Path


def quoted(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def replace_assignment(text: str, key: str, value: str) -> str:
    lines = []
    for line in text.splitlines():
        if line.startswith(key + "=") or line.startswith(key + " ="):
            lines.append(f"{key}={value}")
        else:
            lines.append(line)
    return "\n".join(lines) + "\n"


def main() -> None:
    path = Path("export_presets.cfg")
    text = path.read_text()
    build = os.environ["GITHUB_RUN_NUMBER"]
    text = replace_assignment(text, "version/code", build)
    text = replace_assignment(text, "application/version", quoted(build))

    debug_path = os.environ["ANDROID_DEBUG_KEYSTORE"]
    text = replace_assignment(text, "keystore/debug", quoted(debug_path))
    text = replace_assignment(text, "keystore/debug_user", quoted("androiddebugkey"))
    text = replace_assignment(text, "keystore/debug_password", quoted("android"))

    release_b64 = os.environ.get("ANDROID_KEYSTORE_B64", "")
    release_pass = os.environ.get("ANDROID_KEYSTORE_PASSWORD", "")
    release_alias = os.environ.get("ANDROID_KEY_ALIAS", "")
    if release_b64 and release_pass and release_alias:
        text = replace_assignment(text, "keystore/release", quoted(os.environ["ANDROID_RELEASE_KEYSTORE"]))
        text = replace_assignment(text, "keystore/release_user", quoted(release_alias))
        text = replace_assignment(text, "keystore/release_password", quoted(release_pass))
        print("Using the release keystore from secrets")
    else:
        print("Release keystore secrets are not all set; Android artifacts will be debug-signed")
    path.write_text(text)


if __name__ == "__main__":
    main()
