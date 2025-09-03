#!/usr/bin/env bash

set -euo pipefail

# Detect OS type
OS_TYPE="$(uname -s)"
APT_UPDATED=0

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

apt_update_once() {
    if [[ $APT_UPDATED -eq 0 ]]; then
        sudo apt-get update -qq -y
        APT_UPDATED=1
    fi
}

install_package() {
    local pkg="$1"
    case "$OS_TYPE" in
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                echo "Install Homebrew first"; exit 1
            fi
            brew list --versions "$pkg" >/dev/null 2>&1 || brew install "$pkg"
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                apt_update_once
                sudo NEEDRESTART_MODE=a apt-get install -y -qq "$pkg"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y -q "$pkg"
            else
                echo "Unsupported Linux package manager. Install $pkg manually."; exit 1
            fi
            ;;
        *) echo "Unsupported OS: $OS_TYPE"; exit 1 ;;
    esac
}

install_hashicorp_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            brew tap hashicorp/tap >/dev/null 2>&1 || true
            brew install "hashicorp/tap/$tool"
        elif [[ "$OS_TYPE" == "Linux" ]]; then
            ensure_hashicorp_repo
            apt_update_once
            install_package "$tool"
        fi
    fi
}

ensure_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    command -v "$cmd" >/dev/null 2>&1 || install_package "$pkg"
}

# ------------------------------------------------------------
# Special installers
# ------------------------------------------------------------

ensure_gcloud() {
    if ! command -v gcloud >/dev/null 2>&1 && [[ "$OS_TYPE" == "Linux" ]]; then
            install_package apt-transport-https
            install_package ca-certificates
            install_package gnupg
            install_package curl
            curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
                sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
                sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
            sudo apt-get update
            sudo apt-get install -y google-cloud-cli >/dev/null
    elif ! command -v gcloud >/dev/null 2>&1 && [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install gcloud-cli
    fi
}

ensure_gke_plugin() {
    if ! command -v gke-gcloud-auth-plugin >/dev/null 2>&1 && [[ "$OS_TYPE" == "Linux" ]]; then
        install_package google-cloud-sdk-gke-gcloud-auth-plugin >/dev/null
    fi
}

ensure_helm() {
    if ! command -v helm >/dev/null 2>&1 && [[ "$OS_TYPE" == "Linux" ]]; then
        curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor | \
          sudo tee /usr/share/keyrings/helm.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
          sudo tee /etc/apt/sources.list.d/helm-stable-debian.list >/dev/null
    fi
}

ensure_hashicorp_repo() {
    if [[ "$OS_TYPE" == "Linux" ]] && [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
        wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
          sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
          sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    fi
}

ensure_kubectl() {
    if ! command -v kubectl >/dev/null 2>&1 && [[ "$OS_TYPE" == "Linux" ]]; then
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | \
          sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
          sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
    fi
}

# ------------------------------------------------------------
# Tool installs
# ------------------------------------------------------------

ensure_gcloud
ensure_gke_plugin
ensure_kubectl
ensure_helm
ensure_hashicorp_repo
ensure_command make
ensure_command jq
ensure_command docker-buildx
ensure_command pass
ensure_command helm
ensure_command kubectl
install_hashicorp_tool terraform
install_hashicorp_tool vault