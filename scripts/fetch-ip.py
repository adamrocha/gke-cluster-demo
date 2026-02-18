#!/usr/bin/env python3
"""
fetch_ip.py
Retrieves the public IPv4 address of the machine and outputs it in JSON format.
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

PUBLIC_IP_URL = "https://4.ident.me"
ALLOWED_URL_SCHEMES = {"https"}
ALLOWED_URL_HOSTS = {"4.ident.me"}


def validate_fetch_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in ALLOWED_URL_SCHEMES:
        raise ValueError(f"URL scheme '{parsed.scheme}' is not allowed")
    if not parsed.netloc:
        raise ValueError("URL must include a network location")
    if parsed.hostname not in ALLOWED_URL_HOSTS:
        raise ValueError(f"URL host '{parsed.hostname}' is not allowed")
    return url


def get_public_ip():
    try:
        url = validate_fetch_url(PUBLIC_IP_URL)
        with urllib.request.urlopen(
            url, timeout=10
        ) as response:  # nosec B310 - URL is validated against explicit scheme and host allowlists
            ip = response.read().decode().strip()
        return ip
    except (urllib.error.URLError, ValueError) as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


def main():
    ip = get_public_ip()
    print(json.dumps({"ip": ip}))


if __name__ == "__main__":
    main()
