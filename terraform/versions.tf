terraform {
  required_version = "<= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.12"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.5"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
