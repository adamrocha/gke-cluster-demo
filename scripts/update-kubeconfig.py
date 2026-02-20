#!/usr/bin/env python3
"""
This script updates the kubeconfig file to access the GKE cluster.
"""

import subprocess  # nosec B404 - subprocess is used with static args and shell=False
import sys

GCP_PROJECT_ID = "gke-cluster-458701"
REGION = "us-central1"
CLUSTER_NAME = "gke-cluster-demo"


def main():
    cmd = (
        "gcloud",
        "container",
        "clusters",
        "get-credentials",
        CLUSTER_NAME,
        "--region",
        REGION,
        "--project",
        GCP_PROJECT_ID,
    )
    try:
        print(f"Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True, shell=False)  # nosec B603
        print("✅ kubeconfig updated successfully.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to update kubeconfig: {e}", file=sys.stderr)
        sys.exit(e.returncode)


if __name__ == "__main__":
    main()
