#!/usr/bin/env bash
set -euo pipefail

az config set extension.dynamic_install_allow_preview=true
az extension add --name application-insights --allow-preview True

uv venv --clear
uv venv .venv
source .venv/bin/activate
uv sync
