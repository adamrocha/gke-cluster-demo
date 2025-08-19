resource "helm_release" "vault" {
  depends_on = [google_container_node_pool.gke_pool]
  name       = "vault"
  namespace  = var.vault_ns
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.30.1"
  timeout    = 600

  create_namespace = true

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
  set {
    name  = "server.ui"
    value = "true"
  }
  set {
    name  = "server.ha.enabled"
    value = "true"
  }
  set {
    name  = "server.ha.replicas"
    value = "3"
  }
  set {
    name  = "server.ha.storage.type"
    value = "consul"
  }
  set {
    name  = "server.ha.storage.consul.address"
    value = "consul:8500"
  }
  set {
    name  = "server.ha.storage.consul.path"
    value = "vault/"
  }
  set {
    name  = "injector.enabled"
    value = "true"
  }
  set {
    name  = "injector.replicaCount"
    value = "1"
  }
  set {
    name  = "injector.authPath"
    value = "auth/kubernetes"
  }
  set {
    name  = "injector.logLevel"
    value = "info"
  }
  set {
    name  = "injector.logLevel"
    value = "info"
  }
}

resource "null_resource" "wait_for_vault" {
  depends_on = [helm_release.vault]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for Vault to be ready..."
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n ${var.vault_ns} --timeout=180s
    EOT
  }
}

resource "null_resource" "vault_port_forward" {
  depends_on = [helm_release.vault]

  provisioner "local-exec" {
    command = <<EOT
      echo "Starting Vault port-forward..."
      kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200 >/tmp/vault-pf.log 2>&1 &
      echo "Vault UI should be available at http://localhost:8200/ui"
      echo "To stop port-forward, kill the background process:"
      echo "pkill -f 'kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200'"
    EOT
    # Keep this running during apply, or run detached (this is a simple fire-and-forget)
  }
}

resource "null_resource" "vault_init" {
  depends_on = [null_resource.wait_for_vault]
  
  provisioner "local-exec" {
    command = <<EOT
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Checking Vault initialization status..."
      IS_INIT=$(kubectl exec -n ${var.vault_ns} vault-0 -- vault status -format=json | jq -r '.initialized')

      if [ "$IS_INIT" = "true" ]; then
        echo "Vault is already initialized, skipping init" || true
        pkill -f 'kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200' 2>&1
      else
        echo "Initializing Vault..."
        kubectl exec -n ${var.vault_ns} vault-0 -- vault operator init -key-shares=1 -key-threshold=1 > ~/vault_init.txt

        VAULT_UNSEAL_KEY=$(grep 'Unseal Key 1:' vault_init.txt | awk '{print $4}')
        VAULT_ROOT_TOKEN=$(grep 'Initial Root Token:' vault_init.txt | awk '{print $4}')

        echo "Unsealing Vault..."
        kubectl exec -n vault-ns vault-0 -- vault operator unseal "$VAULT_UNSEAL_KEY"

        # echo "$VAULT_ROOT_TOKEN" > ~/.vault-token
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "vault_store_kubeconfig" {
  depends_on = [null_resource.vault_init]

  provisioner "local-exec" {
    command = <<EOT
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Starting Vault port-forward for storing kubeconfig..."
      kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200 >/tmp/vault-pf.log 2>&1 &
      PF_PID=$!

      # Wait for Vault port to be ready (increase retries if needed)
      for i in {1..15}; do
        nc -z localhost 8200 && break
        sleep 2
      done

      export VAULT_ADDR='http://127.0.0.1:8200'
      # export VAULT_TOKEN=$(cat ~/.vault-token)

      echo "Backing up current kubeconfig to ~/.kube/config.bak"
      mkdir -p ~/.kube
      if [ -f ~/.kube/config ]; then
        cp ~/.kube/config ~/.kube/config.bak
      fi

      echo "Generating fresh kubeconfig with gcloud CLI"
      gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${var.region}

      echo "Storing kubeconfig in Vault..."
      cat ~/.kube/config | vault kv put secret/kubeconfig value=-

      echo "Stopping port-forward..."
      kill $PF_PID 2>&1
      # pkill -f 'kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200' || true
    EOT
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "vault_retrieve_kubeconfig" {
  depends_on = [null_resource.vault_store_kubeconfig]

  provisioner "local-exec" {
    command = <<EOT
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Starting Vault port-forward for retrieving kubeconfig..."
      kubectl port-forward svc/vault -n vault-ns 8200:8200 >/tmp/vault-pf.log 2>&1 &
      PF_PID=$!

      for i in {1..15}; do
        nc -z localhost 8200 && break
        sleep 2
      done

      export VAULT_ADDR='http://127.0.0.1:8200'
      # export VAULT_TOKEN=$(cat ~/.vault-token)

      echo "Backing up existing kubeconfig to ~/.kube/config.bak"
      mkdir -p ~/.kube
      if [ -f ~/.kube/config ]; then
        cp ~/.kube/config ~/.kube/config.bak
      fi

      echo "Retrieving kubeconfig from Vault into temp file..."
      vault kv get -field=value secret/kubeconfig > ~/.kube/config.tmp

      echo "Validating retrieved kubeconfig..."
      if kubectl --kubeconfig ~/.kube/config.tmp get nodes >/dev/null 2>&1; then
        echo "Valid kubeconfig retrieved, replacing active config..."
        mv ~/.kube/config.tmp ~/.kube/config
      else
        echo "Retrieved kubeconfig is invalid! Keeping existing config."
        rm ~/.kube/config.tmp
        exit 1
      fi

      echo "Stopping port-forward..."
      kill $PF_PID 2>&1
      # pkill -f 'kubectl port-forward svc/vault -n ${var.vault_ns} 8200:8200' || true
    EOT
    interpreter = ["bash", "-c"]
  }
}
