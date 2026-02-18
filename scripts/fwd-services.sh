#!/usr/bin/env bash

# Forward ports for services
kubectl port-forward -n vault-ns svc/vault 8200:8200 >/tmp/vault-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-prometheus-node-exporter 9100:9100 >/tmp/exporter-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-grafana 3000:80 >/tmp/grafana-pf.log 2>&1 &
kubectl port-forward -n monitoring-ns svc/prometheus-kube-prometheus-prometheus 9090:9090 >/tmp/prometheus-pf.log 2>&1 &
