#!/usr/bin/env bash
set -euo pipefail

# Railway/Nixpacks already installs dependencies before this script runs.
# Running npm ci again can fail with EBUSY on node_modules/.cache.
npm run build