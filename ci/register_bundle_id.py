#!/usr/bin/env python3
"""Register the iOS bundle id with App Store Connect if it does not exist yet."""

import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt


def token() -> str:
    key_path = os.environ["KEYFILE"]
    with open(key_path, "r", encoding="utf-8") as handle:
        private_key = handle.read()
    now = int(time.time())
    return jwt.encode(
        {
            "iss": os.environ["APPSTORE_API_ISSUER_ID"],
            "iat": now,
            "exp": now + 10 * 60,
            "aud": "appstoreconnect-v1",
        },
        private_key,
        algorithm="ES256",
        headers={"kid": os.environ["APPSTORE_API_KEY_ID"], "typ": "JWT"},
    )


def main() -> int:
    bundle_id = os.environ["BUNDLE_ID"]
    body = json.dumps(
        {
            "data": {
                "type": "bundleIds",
                "attributes": {
                    "identifier": bundle_id,
                    "name": "Cobblewick",
                    "platform": "IOS",
                },
            }
        }
    ).encode()
    request = urllib.request.Request(
        "https://api.appstoreconnect.apple.com/v1/bundleIds",
        data=body,
        headers={
            "Authorization": f"Bearer {token()}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request) as response:
            print(f"Registered bundle id {bundle_id} ({response.status})")
            return 0
    except urllib.error.HTTPError as error:
        payload = error.read().decode("utf-8", errors="replace")
        duplicate = error.code == 409 or "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE" in payload
        if duplicate:
            print(f"Bundle id {bundle_id} is already registered")
            return 0
        print(f"App Store Connect bundle id registration failed ({error.code})", file=sys.stderr)
        print(payload[:2000], file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
