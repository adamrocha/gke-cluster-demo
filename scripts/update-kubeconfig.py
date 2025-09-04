#!/usr/bin/env python3
"""
This script updates the kubeconfig file to access the GKE cluster.
"""

import subprocess
import sys

PROJECT_ID = "gke-cluster-458701"
REGION = "us-central1"
CLUSTER_NAME = "demo-cluster"

def main():
    cmd = [
        "gcloud", "container", "clusters", "get-credentials",
        CLUSTER_NAME,
        "--region", REGION,
        "--project", PROJECT_ID
    ]
    try:
        print(f"Running: {' '.join(cmd)}")
        subprocess.check_call(cmd)
        print("✅ kubeconfig updated successfully.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to update kubeconfig: {e}", file=sys.stderr)
        sys.exit(e.returncode)

if __name__ == "__main__":
        main()