#!/usr/bin/env bash
# This script retrieves the public IPv4 address of the machine and outputs it in JSON format.

IP=$(curl -s https://4.ident.me)
jq -n --arg ip "$IP" '{ip: $ip}'