# Production Architecture with Cloud Armor

## Overview

This document describes the production-grade architecture for the GKE cluster with integrated security and load balancing.

## Architecture Flow

```text
Internet
    ↓
External HTTP(S) Load Balancer (Global)
    ↓
Cloud Armor Security Policy
    ↓
Backend Service (NEG - Network Endpoint Group)
    ↓
GKE Service
    ↓
Pods (Container-Optimized OS nodes)
```

## Components

### 1. External HTTP(S) Load Balancer

- **Type**: Global Load Balancer
- **Static IP**: Pre-provisioned via `google_compute_global_address.gke_lb_ip`
- **SSL/TLS**: GCE SSL certificate referenced by Ingress `ingress.gcp.kubernetes.io/pre-shared-cert`
- **Creation**: Automatically provisioned by GKE Ingress controller

### 2. Cloud Armor Security Policy

Provides DDoS protection and Web Application Firewall (WAF) capabilities.

**Protections Enabled:**

- Rate limiting (100 requests/minute per IP)
- SQL injection protection
- Cross-site scripting (XSS) protection
- Local file inclusion (LFI) protection
- Remote code execution (RCE) protection
- Scanner detection
- Protocol attack protection
- Session fixation protection
- Adaptive Layer 7 DDoS defense

**Configuration**: `terraform/security.tf`

### 3. Backend Service

Configured via `BackendConfig` CRD with:

- Health checks (HTTP, port 8080, path `/`)
- Connection draining (60 seconds)
- Session affinity (CLIENT_IP)
- Request timeout (30 seconds)
- Access logging (100% sample rate)

### 4. Network Endpoint Groups (NEG)

- Directly route traffic to Pod IPs (bypassing iptables overhead)
- Better observability and health checking
- Enabled via `cloud.google.com/neg: '{"ingress": true}'` annotation

## Deployment Steps

### 1. Deploy Terraform Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:

- GKE cluster with private nodes
- VPC with proper network segmentation
- Cloud Armor security policy
- Global static IP for load balancer

### 2. Deploy Kubernetes Resources

```bash
# Deploy namespace
kubectl apply -f manifests/hello-world-ns.yaml

# Deploy network policies
kubectl apply -f manifests/hello-world-networkpolicy.yaml

# Deploy application
kubectl apply -f manifests/hello-world-deployment.yaml

# Deploy service
kubectl apply -f manifests/hello-world-service.yaml

# Deploy ingress (creates load balancer with Cloud Armor)
kubectl apply -f manifests/hello-world-ingress.yaml
```

### 3. Verify Cloud Armor Integration

```bash
# Check ingress status
kubectl get ingress -n hello-world-ns

# Get the load balancer IP
kubectl get ingress hello-world-ingress -n hello-world-ns -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Check backend services (Cloud Console or gcloud)
gcloud compute backend-services list

# Verify Cloud Armor policy is attached
gcloud compute backend-services describe <backend-service-name> --global
```

## Security Features

### Cloud Armor Rules

| Priority | Rule                | Action         | Description                      |
| -------- | ------------------- | -------------- | -------------------------------- |
| 1000     | Block malicious IPs | deny(403)      | Blocks known bad actors          |
| 2000     | Rate limiting       | rate_based_ban | 100 req/min per IP, 10min ban    |
| 3000     | SQL injection       | deny(403)      | OWASP Top 10 protection          |
| 4000     | XSS                 | deny(403)      | Cross-site scripting defense     |
| 5000     | LFI                 | deny(403)      | Local file inclusion protection  |
| 6000     | RCE                 | deny(403)      | Remote code execution prevention |
| 7000     | Scanner detection   | deny(403)      | Block security scanners          |
| 8000     | Protocol attacks    | deny(403)      | HTTP protocol attack mitigation  |
| 9000     | Session fixation    | deny(403)      | Session security                 |

### Adaptive Protection

Layer 7 DDoS defense is enabled, which:

- Automatically detects and mitigates DDoS attacks
- Uses machine learning to identify attack patterns
- Scales protection based on threat level

## Monitoring and Logging

### Cloud Armor Logs

View security events in Cloud Logging:

```bash
gcloud logging read "resource.type=http_load_balancer AND jsonPayload.enforcedSecurityPolicy.name=cloud-armor-policy" --limit 50
```

### Backend Service Metrics

Monitor in Cloud Monitoring:

- Request count
- Request latency (p50, p95, p99)
- Error rate (4xx, 5xx)
- Backend latency
- Cloud Armor rule hits

### Alerting

Set up alerts for:

- High rate of Cloud Armor denials (potential attack)
- Elevated error rates (5xx)
- Unhealthy backend instances
- SSL certificate expiration

## Cost Optimization

1. **Load Balancer**: Charged per hour + forwarding rules
2. **Cloud Armor**: $0.75/policy/month + $0.50/million requests
3. **NEG**: No additional cost
4. **Managed Certificates**: Free
5. **VPC Flow Logs**: Based on log volume (enable export to reduce costs)

## Updating Cloud Armor Rules

To add custom rules:

1. Edit `terraform/security.tf`
2. Add new rule block with unique priority
3. Apply changes:

```bash
terraform plan
terraform apply
```

Changes are applied without disrupting traffic.

## Troubleshooting

### Traffic Not Reaching Pods

1. Check Ingress status: `kubectl describe ingress -n hello-world-ns`
2. Verify Service endpoints: `kubectl get endpoints -n hello-world-ns`
3. Check firewall rules allow traffic from load balancer IPs
4. Verify health checks are passing in GCP Console

### Cloud Armor Blocking Legitimate Traffic

1. Check Cloud Armor logs for specific rule hits
2. Adjust rule sensitivity or add allow-list rules
3. Consider IP-based exemptions for trusted sources

### SSL Certificate Issues

1. Verify domain ownership
2. Check DNS points to load balancer IP
3. Certificate provisioning can take 15-30 minutes
4. Check Ingress certificate annotation: `kubectl get ingress hello-world-ingress -n hello-world-ns -o jsonpath='{.metadata.annotations.ingress\.gcp\.kubernetes\.io/pre-shared-cert}'`
5. Verify certificate exists in GCP: `gcloud compute ssl-certificates list --global`

## Best Practices

1. **Always use HTTPS** - Attach a valid pre-shared GCE SSL certificate to Ingress
2. **Monitor Cloud Armor logs** - Set up alerts for anomalies
3. **Regular rule updates** - Keep security policies current
4. **Test in staging** - Validate rule changes before production
5. **Use NEGs** - Better performance and observability
6. **Enable CDN** - For static content (if applicable)
7. **Implement IAP** - For authenticated access (if needed)
8. **Rate limit APIs** - Prevent abuse and resource exhaustion

## References

- [Google Cloud Armor](https://cloud.google.com/armor/docs)
- [GKE Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)
- [BackendConfig CRD](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)
- [Google-managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs)
- [Network Endpoint Groups](https://cloud.google.com/load-balancing/docs/negs)
