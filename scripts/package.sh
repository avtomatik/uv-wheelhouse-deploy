#!/usr/bin/env bash
set -euo pipefail

PROJECT=${1:?project directory required}
cd "$PROJECT"
zip -r "../${PROJECT}.zip" \
    src \
    requirements.txt \
    wheels \
    scripts/windows \
    deploy_config.yaml
