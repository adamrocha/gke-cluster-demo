# Blue/Green Deployment Guide

## Overview

Blue/Green deployment is a release strategy that reduces downtime and risk by running two identical production environments called Blue and Green. Only one environment serves production traffic at a time.

## How It Works

1. **Blue** (current version) serves all production traffic
2. **Green** (new version) is deployed alongside Blue
3. Test Green thoroughly without affecting users
4. Switch traffic from Blue to Green instantly
5. Keep Blue running for quick rollback if needed
6. After validation, decommission Blue or prepare it for next release

## Architecture

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                    LoadBalancer Service                      │
│              (selector: version: blue/green)                 │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴────────────┐
                │                        │
        ┌───────▼───────┐        ┌──────▼────────┐
        │  Blue Pods    │        │  Green Pods   │
        │  (v1.2.5)     │        │  (v1.2.6)     │
        │  3 replicas   │        │  3 replicas   │
        └───────────────┘        └───────────────┘
```

## Prerequisites

- GKE cluster running
- kubectl configured
- Docker images in Google Artifact Registry
- Namespace created (`hello-world-ns`)

## Quick Start

### 1. Deploy Blue/Green Infrastructure

```sh
# Deploy both blue and green deployments
make bg-deploy

# Or manually
kubectl apply -k manifests/blue-green/
```

This creates:

- Namespace: `hello-world-ns`
- Deployment: `hello-world-blue` (3 replicas)
- Deployment: `hello-world-green` (3 replicas)
- Service: `hello-world-service` (pointing to blue initially)

### 2. Check Status

```sh
# View all resources
make bg-status

# Manual check
kubectl get all -n hello-world-ns

# Check which version is active
kubectl get service hello-world-service -n hello-world-ns -o yaml | grep version:
```

### 3. Test Green Deployment

Before switching traffic, test the green deployment:

```sh
# Port-forward to green deployment
make bg-test-green

# In another terminal, test
curl http://localhost:8081

# View green logs
make bg-logs-green
```

### 4. Switch Traffic to Green

After validating green deployment:

```sh
# Switch traffic to green
make bg-switch-green

# Verify switch
kubectl get service hello-world-service -n hello-world-ns -o yaml | grep version:
```

### 5. Monitor and Validate

```sh
# Check service endpoint
make k8s-status

# Monitor logs
make bg-logs-green

# Check metrics (if monitoring is enabled)
kubectl top pods -n hello-world-ns
```

### 6. Rollback (if needed)

If issues are detected:

```sh
# Instant rollback to blue
make bg-rollback

# Or manually
kubectl patch service hello-world-service -n hello-world-ns -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Deployment Workflow

### Scenario: Deploying v1.2.6

**Current State:** Blue (v1.2.5) serving production traffic

#### Step 1: Update Green Deployment

Edit `manifests/blue-green/hello-world-deployment-green.yaml`:

```yaml
containers:
  - name: hello-world
    image: us-central1-docker.pkg.dev/gke-cluster-458701/hello-world-repo/hello-world:1.2.6
    # ... rest of config
```

Apply changes:

```sh
kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml

# Wait for rollout
kubectl rollout status deployment/hello-world-green -n hello-world-ns
```

#### Step 2: Test Green

```sh
# Port-forward to green pod
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8081:8080

# Run tests
curl http://localhost:8081
curl http://localhost:8081/health
```

#### Step 3: Switch Traffic

```sh
make bg-switch-green

# Or manually
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"green"}}}'
```

#### Step 4: Monitor

```sh
# Watch for errors
kubectl logs -f -n hello-world-ns -l version=green

# Check metrics
kubectl top pods -n hello-world-ns -l version=green
```

#### Step 5: Update Blue for Next Release

After green is stable, update blue to v1.2.6:

```sh
kubectl apply -f manifests/blue-green/hello-world-deployment-blue.yaml
```

Now both are on v1.2.6, ready for next release cycle.

## Switching Commands

### Switch to Blue

```sh
make bg-switch-blue

# Manual
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Switch to Green

```sh
make bg-switch-green

# Manual
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"green"}}}'
```

### Quick Rollback

```sh
make bg-rollback

# This switches to the previous version
# If currently on green → switches to blue
# If currently on blue → switches to green
```

## Testing Strategies

### Smoke Testing

```sh
# Test basic functionality
kubectl run -it --rm test --image=curlimages/curl -n hello-world-ns -- \
  curl http://hello-world-service/

# Test from within cluster
kubectl run -it --rm test --image=curlimages/curl -n hello-world-ns -- \
  curl http://hello-world-service.hello-world-ns.svc.cluster.local/
```

### Load Testing

```sh
# Using kubectl run
kubectl run -it --rm loadtest --image=williamyeh/wrk -n hello-world-ns -- \
  wrk -t4 -c100 -d30s http://hello-world-service/

# Using external tools
# Install hey: go install github.com/rakyll/hey@latest
hey -z 30s -c 50 http://EXTERNAL_IP/
```

### Canary Testing

Before full switch, gradually shift traffic:

```sh
# Create a weighted service (advanced)
# This requires additional configuration with Istio or similar
```

## Monitoring

### Check Active Version

```sh
# Check service selector
kubectl get svc hello-world-service -n hello-world-ns -o jsonpath='{.spec.selector.version}'

# Check pod labels
kubectl get pods -n hello-world-ns --show-labels
```

### View Deployment Stats

```sh
# Blue deployment
kubectl describe deployment hello-world-blue -n hello-world-ns

# Green deployment
kubectl describe deployment hello-world-green -n hello-world-ns
```

### Resource Usage

```sh
# Pod metrics
kubectl top pods -n hello-world-ns

# Node metrics
kubectl top nodes
```

## Cleanup

### Remove Blue/Green Setup

```sh
make bg-cleanup

# Or manually
kubectl delete -k manifests/blue-green/
```

### Delete Specific Deployment

```sh
# Delete only blue
kubectl delete deployment hello-world-blue -n hello-world-ns

# Delete only green
kubectl delete deployment hello-world-green -n hello-world-ns
```

## Advanced: Automated Blue/Green Script

A helper script `scripts/blue-green-switch.sh` automates switching:

```sh
#!/usr/bin/env bash
# scripts/blue-green-switch.sh

NAMESPACE="hello-world-ns"
SERVICE="hello-world-service"

case "$1" in
  blue)
    kubectl patch svc $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"version":"blue"}}}'
    ;;
  green)
    kubectl patch svc $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"version":"green"}}}'
    ;;
  status)
    kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}'
    ;;
  rollback)
    CURRENT=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
    if [ "$CURRENT" = "blue" ]; then
      kubectl patch svc $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"version":"green"}}}'
    else
      kubectl patch svc $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"version":"blue"}}}'
    fi
    ;;
esac
```

## Key Benefits

- ✅ **Zero Downtime:** Instant traffic switch
- ✅ **Fast Rollback:** Revert in seconds
- ✅ **Full Testing:** Test new version before exposing to users
- ✅ **Reduced Risk:** Both versions run simultaneously
- ✅ **Easy Validation:** Compare versions side-by-side

## Trade-offs

- ⚠️ **Resource Usage:** Requires 2x resources during deployment
- ⚠️ **Database Migrations:** Requires backward-compatible schemas
- ⚠️ **Session Handling:** May need sticky sessions or session migration

## Best Practices

1. **Test thoroughly** before switching traffic
2. **Monitor metrics** closely after switch
3. **Keep rollback plan** ready
4. **Use health checks** to ensure pods are ready
5. **Automate testing** with smoke tests
6. **Document** which version is active
7. **Clean up** old version after validation period
8. **Use feature flags** for gradual rollout

## Troubleshooting

### Pods Not Ready

```sh
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns
```

### Service Not Routing

```sh
# Check service selector
kubectl describe svc hello-world-service -n hello-world-ns

# Check endpoints
kubectl get endpoints hello-world-service -n hello-world-ns
```

### Image Pull Errors

```sh
# Verify image exists
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/gke-cluster-458701/hello-world-repo
```

## References

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Martin Fowler: BlueGreenDeployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
