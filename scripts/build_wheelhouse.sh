#!/usr/bin/env bash
set -euo pipefail

uv pip download \
    -r requirements.txt \
    --python-version 3.12.4 \
    --platform win_amd64 \
    --only-binary=:all: \
    -o wheels
