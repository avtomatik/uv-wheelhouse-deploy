#!/usr/bin/env bash
set -euo pipefail

echo "Exporting requirements.txt"
uv export \
  --format requirements.txt \
  --no-hashes \
  > requirements.txt
echo "Done"
