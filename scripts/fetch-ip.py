#!/usr/bin/env python3
"""
fetch_ip.py
Retrieves the public IPv4 address of the machine and outputs it in JSON format.
"""
import json
import urllib.request

def get_public_ip():
    try:
        with urllib.request.urlopen("https://4.ident.me") as response:
            ip = response.read().decode().strip()
        return ip
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        exit(1)

def main():
    ip = get_public_ip()
    print(json.dumps({"ip": ip}))

if __name__ == "__main__":
    main()
