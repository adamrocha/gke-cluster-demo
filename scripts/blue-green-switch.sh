#!/usr/bin/env bash
# Blue/Green deployment switcher script for GKE

set -euo pipefail

NAMESPACE="hello-world-ns"
SERVICE="hello-world-service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
# BLUE='\033[0;34m'
NC='\033[0m' # No Color

get_current_version() {
    kubectl get svc "${SERVICE}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "unknown"
}

check_deployment_ready() {
    local version=$1
    local deployment="hello-world-${version}"
    
    if ! kubectl get deployment "${deployment}" -n "${NAMESPACE}" &>/dev/null; then
        echo "❌ Deployment ${deployment} not found"
        return 1
    fi
    
    local ready 
    ready=$(kubectl get deployment "${deployment}" -n "${NAMESPACE}" \
        -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired
    desired=$(kubectl get deployment "${deployment}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [[ "${ready}" = "${desired}" ]] && [[ "${ready}" != "0" ]]; then
        return 0
    else
        echo "⚠️  Deployment ${deployment} not ready: ${ready}/${desired} replicas"
        return 1
    fi
}

switch_to() {
    local target_version=$1
    local current_version
    current_version=$(get_current_version)
    
    echo "🔄 Current version: ${current_version}"
    echo "🎯 Target version: ${target_version}"
    
    # Check if target deployment is ready
    if ! check_deployment_ready "${target_version}"; then
        echo "❌ Cannot switch to ${target_version} - deployment not ready"
        exit 1
    fi
    
    # Perform switch
    kubectl patch svc "${SERVICE}" -n "${NAMESPACE}" \
        -p "{\"spec\":{\"selector\":{\"version\":\"${target_version}\"}}}"
    
    echo "✅ Traffic switched to ${target_version}"
    
    # Wait a moment and verify
    sleep 2
    local new_version
    new_version=$(get_current_version)
    if [[ "${new_version}" = "${target_version}" ]]; then
        echo -e "${GREEN}✓${NC} Switch verified successfully"
    else
        echo -e "${RED}✗${NC} Switch verification failed"
        exit 1
    fi
}

show_status() {
    echo "📊 Blue/Green Deployment Status"
    echo "================================"
    echo ""
    
    local current
    current=$(get_current_version)
    echo "🎯 Active version: ${current}"
    echo ""
    
    echo "🔵 Blue Deployment:"
    kubectl get deployment hello-world-blue -n "${NAMESPACE}" 2>/dev/null || echo "  Not deployed"
    echo ""
    
    echo "🟢 Green Deployment:"
    kubectl get deployment hello-world-green -n "${NAMESPACE}" 2>/dev/null || echo "  Not deployed"
    echo ""
    
    echo "🌐 Service:"
    kubectl get svc "${SERVICE}" -n "${NAMESPACE}" 2>/dev/null || echo "  Not found"
    echo ""
    
    echo "📦 Pods:"
    kubectl get pods -n "${NAMESPACE}" -l app=hello-world 2>/dev/null || echo "  No pods found"
}

rollback() {
    local current
    current=$(get_current_version)
    local target=""
    
    if [[ "${current}" = "blue" ]]; then
        target="green"
    elif [[ "${current}" = "green" ]]; then
        target="blue"
    else
        echo "❌ Cannot determine rollback target from current: ${current}"
        exit 1
    fi
    
    echo "⏮️  Rolling back from ${current} to ${target}"
    switch_to "${target}"
}

case "${1:-status}" in
    blue)
        switch_to "blue"
        ;;
    green)
        switch_to "green"
        ;;
    status)
        show_status
        ;;
    rollback)
        rollback
        ;;
    *)
        echo "Usage: $0 {blue|green|status|rollback}"
        echo ""
        echo "Commands:"
        echo "  blue     - Switch traffic to blue deployment"
        echo "  green    - Switch traffic to green deployment"
        echo "  status   - Show current deployment status"
        echo "  rollback - Rollback to previous version"
        exit 1
        ;;
esac
