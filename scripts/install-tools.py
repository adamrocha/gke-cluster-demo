#!/usr/bin/env python3
"""
Installs required tools for GKE/Terraform demo on macOS or Linux.
"""

import subprocess
import sys
import platform
import shutil
import os

OS_TYPE = platform.system()
APT_UPDATED = False

def run(cmd, check=True, capture_output=False):
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, check=check,
                            stdout=subprocess.PIPE if capture_output else None,
                            stderr=subprocess.PIPE if capture_output else None)
    return result

def apt_update_once():
    global APT_UPDATED
    if not APT_UPDATED:
        run("sudo apt-get update -qq -y")
        APT_UPDATED = True

def install_package(pkg):
    if OS_TYPE == "Darwin":
        if not shutil.which("brew"):
            print("Install Homebrew first")
            sys.exit(1)
        if run(f"brew list --versions {pkg}", check=False).returncode != 0:
            run(f"brew install {pkg}")
    elif OS_TYPE == "Linux":
        if shutil.which("apt-get"):
            apt_update_once()
            run(f"sudo NEEDRESTART_MODE=a apt-get install -y -qq {pkg}")
        elif shutil.which("yum"):
            run(f"sudo yum install -y -q {pkg}")
        else:
            print(f"Unsupported Linux package manager. Install {pkg} manually.")
            sys.exit(1)
    else:
        print(f"Unsupported OS: {OS_TYPE}")
        sys.exit(1)

def install_hashicorp_tool(tool):
    if not shutil.which(tool):
        if OS_TYPE == "Darwin":
            run("brew tap hashicorp/tap", check=False)
            run(f"brew install hashicorp/tap/{tool}")
        elif OS_TYPE == "Linux":
            ensure_hashicorp_repo()
            apt_update_once()
            install_package(tool)
        else:
            print(f"Unsupported OS for installing {tool}: {OS_TYPE}")
            sys.exit(1)
def ensure_command(cmd, pkg=None):
    if not shutil.which(cmd):
        install_package(pkg or cmd)

def ensure_gcloud():
    if not shutil.which("gcloud"):
        if OS_TYPE == "Linux":
            install_package("apt-transport-https")
            install_package("ca-certificates")
            install_package("gnupg")
            install_package("curl")
            run("curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg")
            run('echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list')
            apt_update_once()
            run("sudo apt-get install -y google-cloud-cli")
        elif OS_TYPE == "Darwin":
            run("brew install google-cloud-cli")

def ensure_gke_plugin():
    if not shutil.which("gke-gcloud-auth-plugin") and OS_TYPE == "Linux":
        install_package("google-cloud-sdk-gke-gcloud-auth-plugin")

def ensure_helm():
    if not shutil.which("helm") and OS_TYPE == "Linux":
        run("curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg")
        run('echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list')
        apt_update_once()

def ensure_hashicorp_repo():
    if OS_TYPE == "Linux" and not os.path.exists("/etc/apt/sources.list.d/hashicorp.list"):
        run("wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg")
        run('echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list')

def ensure_kubectl():
    if not shutil.which("kubectl") and OS_TYPE == "Linux":
        run("sudo mkdir -p /etc/apt/keyrings")
        run("curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg")
        run('echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list')
        apt_update_once()

def main():
    ensure_gcloud()
    ensure_gke_plugin()
    ensure_kubectl()
    ensure_helm()
    ensure_hashicorp_repo()
    ensure_command("make")
    ensure_command("jq")
    ensure_command("docker-buildx", "docker")
    ensure_command("pass")
    install_hashicorp_tool("terraform")
    install_hashicorp_tool("vault")

if __name__ == "__main__":
    main()