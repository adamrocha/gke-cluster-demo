#!/usr/bin/env bash

# Forward ports for services
kubectl port-forward -n vault-ns svc/vault 8200:8200 &>/dev/null &
kubectl port-forward -n monitoring-ns svc/prometheus-prometheus-node-exporter 9100:9100 &>/dev/null &
kubectl port-forward -n monitoring-ns svc/prometheus-grafana 3000:80 &>/dev/null &
kubectl port-forward -n monitoring-ns svc/prometheus-kube-prometheus-prometheus 9090:9090 &>/dev/null &