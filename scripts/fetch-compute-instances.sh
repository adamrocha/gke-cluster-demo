#!/usr/bin/env bash
# fetch-compute-instances.sh
# Shell wrapper for fetch-compute-instances.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/fetch-compute-instances.py"

# Check if Python script exists
if [[ ! -f ${PYTHON_SCRIPT} ]]; then
	echo "Error: ${PYTHON_SCRIPT} not found" >&2
	exit 1
fi

# Make sure Python script is executable
chmod +x "${PYTHON_SCRIPT}"

# Run Python script with arguments
exec python3 "${PYTHON_SCRIPT}" "$@"
