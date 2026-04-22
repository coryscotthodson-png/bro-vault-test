#!/usr/bin/env bash
set -euo pipefail

echo "=== Compiler (warnings = errors) ==="
forge build

echo "=== Tests (1000 fuzz runs) ==="
forge test -vvv

echo "=== Gas snapshots ==="
forge snapshot

echo "=== Static analysis ==="
forge inspect VulnerableBROVault storageLayout
forge inspect FixedBROVault storageLayout

echo "All checks passed ✓"
