# gke-cluster-demo
## Overview

This project demonstrates how to deploy and manage a Kubernetes cluster on Google Kubernetes Engine (GKE). It includes sample manifests, deployment scripts, and instructions to help you get started quickly.

## Features

- Automated GKE cluster provisioning
- Deployable using Github Actions
- Integration with Google Cloud CLI and kubectl
- Example Kubernetes manifests (Deployments, Services, etc.)
- Development Vault Deployment
- Prometheus Monitoring Stack Deployment
- Scripts for docker image generation and upload to GAR (Google Artifact Registry). Previously known as GCR (Google Container Registry).
- Guidance for authentication and access control

## Tooling

- [GitHub Actions](https://docs.github.com/en/actions)
- [terraform](https://www.terraform.io/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Docker](https://docs.docker.com/engine/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/)

## Usage

1. **Clone the repository:**
```sh
git clone https://github.com/your-org/gke-cluster-demo.git
cd gke-cluster-demo
```

2. **Create the GKE cluster and deploy manifests:**
```sh
make tf-bootstrap
make tf-apply
```

3. **Access the cluster:**
```sh
kubectl get nodes
```

## Tools Used

- **Terraform**: GCP infrastructure provisioning.
- **gcloud**: Google Cloud CLI.
- **helm**: Kubernetes package manager.
- **kubectl**: Command-line tool for interacting with Kubernetes clusters.

## Cleanup

To delete the GKE cluster and associated resources:
```sh
make tf-destroy
```