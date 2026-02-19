# Kubernetes Deployment Guide

## Overview

This guide provides detailed instructions for deploying applications to the GKE cluster using Kubernetes manifests.

## Prerequisites

- GCP CLI (`gcloud`) configured with appropriate credentials
- `kubectl` (v1.28+) installed and configured
- GKE cluster provisioned via Terraform
- kubeconfig updated to point to the cluster
- Docker image available in Google Artifact Registry (GAR)

## Configuration

**Image:** `us-central1-docker.pkg.dev/"${PROJECT_ID}"/hello-world-repo/hello-world:1.2.5`
**Security:** Non-root (UID 10001), read-only root filesystem, dropped capabilities, no privilege escalation  
**Ports:** HTTP 8080→80  
**Resources:** CPU 100m-250m, Memory 64Mi-128Mi  
**Replicas:** 3 (rolling update)  
**Health:** Liveness/readiness probes on `/` port 8080

## Quick Start

### Using Makefile (Recommended)

```sh
# Validate manifests
make k8s-validate

# Deploy to cluster
make k8s-apply

# Check status
make k8s-status

# View logs
make k8s-logs
```

### Using kubectl Directly

```sh
# Apply all manifests
kubectl apply -f manifests/

# Check deployment status
kubectl get all -n hello-world-ns

# Get service endpoint
kubectl get service hello-world-service -n hello-world-ns
```

### Using Kustomize

```sh
# Validate kustomize configuration
kubectl kustomize manifests/ | kubectl apply --dry-run=client -f -

# Deploy with kustomize
kubectl apply -k manifests/

# Preview kustomize output
kubectl kustomize manifests/
```

## Deployment Strategies

### Rolling Update (Default)

The default deployment strategy in `manifests/` uses rolling updates:

- **Max Surge:** 25% (1 additional pod during update)
- **Max Unavailable:** 25% (1 pod can be unavailable)
- **Min Ready Seconds:** 5 seconds before pod is considered ready
- **Progress Deadline:** 300 seconds (5 minutes)

### Blue/Green Deployment

For zero-downtime deployments with instant rollback capability, use the blue-green strategy in `manifests/blue-green/`:

```sh
# Deploy blue-green infrastructure
make bg-deploy

# Check status
make bg-status

# Test blue deployment
make bg-test-blue

# Test green deployment
make bg-test-green

# Switch to green
make bg-switch-green

# Rollback to blue
make bg-rollback
```

See [blue-green-deployment.md](blue-green-deployment.md) for detailed documentation.

## Updating the Application

### Update Image Version

Edit the deployment manifest:

```sh
# Update image tag in deployment
./scripts/update-manifest-image.sh hello-world-repo 1.2.6

# Apply changes
kubectl apply -f manifests/hello-world-deployment.yaml
```

### Rolling Restart

```sh
# Restart deployment without changing image
kubectl rollout restart deployment/hello-world -n hello-world-ns

# Check rollout status
kubectl rollout status deployment/hello-world -n hello-world-ns
```

## Monitoring

### Check Deployment Status

```sh
kubectl get deployments -n hello-world-ns
kubectl describe deployment hello-world -n hello-world-ns
```

### View Pod Status

```sh
kubectl get pods -n hello-world-ns
kubectl describe pod <pod-name> -n hello-world-ns
```

### View Logs

```sh
# All pods
kubectl logs -n hello-world-ns -l app=hello-world --tail=100

# Specific pod
kubectl logs <pod-name> -n hello-world-ns

# Follow logs
kubectl logs -f <pod-name> -n hello-world-ns
```

## Troubleshooting

### Pods Not Starting

```sh
# Check pod events
kubectl describe pod <pod-name> -n hello-world-ns

# Check logs
kubectl logs <pod-name> -n hello-world-ns

# Common issues:
# - Image pull errors: Verify image exists in GAR
# - Resource limits: Check node capacity
# - Security context: Verify user/group IDs
```

### LoadBalancer Not Provisioning

```sh
# Check service events
kubectl describe service hello-world-service -n hello-world-ns

# Verify GCP load balancer
gcloud compute forwarding-rules list

# Check service status
kubectl get service hello-world-service -n hello-world-ns -o yaml
```

### Image Pull Errors

```sh
# Verify image exists
gcloud artifacts docker images list us-central1-docker.pkg.dev/"${PROJECT_ID}"/hello-world-repo

# Check node service account permissions
kubectl describe node | grep serviceAccount

# Verify Workload Identity (if configured)
kubectl get serviceaccount -n hello-world-ns
```

### Performance Issues

```sh
# Check resource usage
kubectl top pods -n hello-world-ns
kubectl top nodes

# Check pod events
kubectl get events -n hello-world-ns --sort-by='.lastTimestamp'

# Increase replicas if needed
kubectl scale deployment hello-world -n hello-world-ns --replicas=5
```

## Cleanup

```sh
# Delete all resources
make k8s-delete

# Or manually
kubectl delete -f manifests/

# Delete namespace (removes all resources)
kubectl delete namespace hello-world-ns
```

## Best Practices

1. **Always validate** manifests before applying: `kubectl apply --dry-run=client`
2. **Use namespaces** to isolate environments
3. **Set resource limits** to prevent resource starvation
4. **Implement health checks** (liveness and readiness probes)
5. **Use security contexts** to run containers as non-root
6. **Enable Pod Security Standards** in namespaces
7. **Use Kustomize** for environment-specific configurations
8. **Version your images** with tags, not `latest`
9. **Monitor deployments** with `kubectl rollout status`
10. **Test in staging** before deploying to production

## Next Steps

- Configure autoscaling: [Horizontal Pod Autoscaler](https://cloud.google.com/kubernetes-engine/docs/how-to/horizontal-pod-autoscaling)
- Set up monitoring: [GKE Monitoring](https://cloud.google.com/stackdriver/docs/solutions/gke)
- Implement GitOps: [Flux](https://fluxcd.io/) or [ArgoCD](https://argoproj.github.io/argo-cd/)
- Configure Ingress: [GKE Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)

## References

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kustomize Documentation](https://kustomize.io/)
