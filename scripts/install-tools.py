#!/usr/bin/env python3
"""
Installs required tools for GKE/Terraform demo on macOS or Linux.
"""

import os
import platform
import shutil
import subprocess  # nosec B404 - subprocess is required for system package tooling; commands are executed with shell=False
import sys
import tempfile
from typing import Sequence

OS_TYPE = platform.system()
APT_UPDATED = False

ALLOWED_BINARIES = {
    "apt-get",
    "brew",
    "curl",
    "dpkg",
    "env",
    "gpg",
    "lsb_release",
    "mkdir",
    "sudo",
    "tee",
    "yum",
}


def validate_cmd(cmd: Sequence[str]) -> None:
    if not cmd:
        raise ValueError("cmd cannot be empty")
    if cmd[0] not in ALLOWED_BINARIES:
        raise ValueError(f"command '{cmd[0]}' is not allowed")
    for arg in cmd:
        if "\x00" in arg or "\n" in arg or "\r" in arg:
            raise ValueError("command arguments contain invalid characters")


def create_temp_file(prefix: str, suffix: str) -> str:
    fd, path = tempfile.mkstemp(prefix=prefix, suffix=suffix)
    os.close(fd)
    return path


def run(
    cmd: Sequence[str],
    check: bool = True,
    capture_output: bool = False,
    input_text: str | None = None,
):
    if isinstance(cmd, str):
        raise TypeError("cmd must be a sequence of arguments, not a shell string")
    validate_cmd(cmd)
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(
        cmd,
        shell=False,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture_output else None,
        stderr=subprocess.PIPE if capture_output else None,
        input=input_text,
    )  # nosec B603 - validated allowlisted argv only, shell disabled
    return result


def apt_update_once():
    global APT_UPDATED
    if not APT_UPDATED:
        run(["sudo", "apt-get", "update", "-qq", "-y"])
        APT_UPDATED = True


def install_package(pkg):
    if OS_TYPE == "Darwin":
        if not shutil.which("brew"):
            print("Install Homebrew first")
            sys.exit(1)
        if run(["brew", "list", "--versions", pkg], check=False).returncode != 0:
            run(["brew", "install", pkg])
    elif OS_TYPE == "Linux":
        if shutil.which("apt-get"):
            apt_update_once()
            run(
                [
                    "sudo",
                    "env",
                    "NEEDRESTART_MODE=a",
                    "apt-get",
                    "install",
                    "-y",
                    "-qq",
                    pkg,
                ]
            )
        elif shutil.which("yum"):
            run(["sudo", "yum", "install", "-y", "-q", pkg])
        else:
            print(f"Unsupported Linux package manager. Install {pkg} manually.")
            sys.exit(1)
    else:
        print(f"Unsupported OS: {OS_TYPE}")
        sys.exit(1)


def install_hashicorp_tool(tool):
    if not shutil.which(tool):
        if OS_TYPE == "Darwin":
            run(["brew", "tap", "hashicorp/tap"], check=False)
            run(["brew", "install", f"hashicorp/tap/{tool}"])
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
            key_tmp = create_temp_file("google-cloud-sdk-", ".gpg.key")
            try:
                run(
                    [
                        "curl",
                        "-fsSL",
                        "https://packages.cloud.google.com/apt/doc/apt-key.gpg",
                        "-o",
                        key_tmp,
                    ]
                )
                run(
                    [
                        "sudo",
                        "gpg",
                        "--dearmor",
                        "--yes",
                        "--output",
                        "/usr/share/keyrings/cloud.google.gpg",
                        key_tmp,
                    ]
                )
            finally:
                os.remove(key_tmp)
            repo_line = "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main\n"
            run(
                ["sudo", "tee", "/etc/apt/sources.list.d/google-cloud-sdk.list"],
                input_text=repo_line,
            )
            apt_update_once()
            run(["sudo", "apt-get", "install", "-y", "google-cloud-cli"])
        elif OS_TYPE == "Darwin":
            run(["brew", "install", "google-cloud-cli"])


def ensure_gke_plugin():
    if not shutil.which("gke-gcloud-auth-plugin") and OS_TYPE == "Linux":
        install_package("google-cloud-sdk-gke-gcloud-auth-plugin")


def ensure_helm():
    if not shutil.which("helm") and OS_TYPE == "Linux":
        arch = run(["dpkg", "--print-architecture"], capture_output=True).stdout.strip()
        key_tmp = create_temp_file("helm-signing-", ".asc")
        try:
            run(
                [
                    "curl",
                    "-fsSL",
                    "https://baltocdn.com/helm/signing.asc",
                    "-o",
                    key_tmp,
                ]
            )
            run(
                [
                    "sudo",
                    "gpg",
                    "--dearmor",
                    "--yes",
                    "--output",
                    "/usr/share/keyrings/helm.gpg",
                    key_tmp,
                ]
            )
        finally:
            os.remove(key_tmp)
        repo_line = f"deb [arch={arch} signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main\\n"
        run(
            ["sudo", "tee", "/etc/apt/sources.list.d/helm-stable-debian.list"],
            input_text=repo_line,
        )
        apt_update_once()


def ensure_hashicorp_repo():
    if OS_TYPE == "Linux" and not os.path.exists(
        "/etc/apt/sources.list.d/hashicorp.list"
    ):
        arch = run(["dpkg", "--print-architecture"], capture_output=True).stdout.strip()
        codename = run(["lsb_release", "-cs"], capture_output=True).stdout.strip()
        key_tmp = create_temp_file("hashicorp-", ".gpg.key")
        try:
            run(
                [
                    "curl",
                    "-fsSL",
                    "https://apt.releases.hashicorp.com/gpg",
                    "-o",
                    key_tmp,
                ]
            )
            run(
                [
                    "sudo",
                    "gpg",
                    "--dearmor",
                    "--yes",
                    "--output",
                    "/usr/share/keyrings/hashicorp-archive-keyring.gpg",
                    key_tmp,
                ]
            )
        finally:
            os.remove(key_tmp)
        repo_line = f"deb [arch={arch} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com {codename} main\\n"
        run(
            ["sudo", "tee", "/etc/apt/sources.list.d/hashicorp.list"],
            input_text=repo_line,
        )


def ensure_kubectl():
    if not shutil.which("kubectl") and OS_TYPE == "Linux":
        run(["sudo", "mkdir", "-p", "/etc/apt/keyrings"])
        key_tmp = create_temp_file("kubernetes-release-", ".key")
        try:
            run(
                [
                    "curl",
                    "-fsSL",
                    "https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key",
                    "-o",
                    key_tmp,
                ]
            )
            run(
                [
                    "sudo",
                    "gpg",
                    "--dearmor",
                    "--yes",
                    "--output",
                    "/etc/apt/keyrings/kubernetes-apt-keyring.gpg",
                    key_tmp,
                ]
            )
        finally:
            os.remove(key_tmp)
        repo_line = "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /\\n"
        run(
            ["sudo", "tee", "/etc/apt/sources.list.d/kubernetes.list"],
            input_text=repo_line,
        )
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
