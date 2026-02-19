#!/bin/bash
set -euo pipefail

# Keep sudo alive
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting full pentest environment setup..."
echo "Root directory: $SCRIPT_DIR"
echo "--------------------------------------------------"

for module in "$SCRIPT_DIR"/modules/*.sh; do
    echo "--------------------------------------------------"
    echo "Executing $(basename "$module")"
    bash "$module"
done

echo "--------------------------------------------------"
echo "Full pentest environment installed."