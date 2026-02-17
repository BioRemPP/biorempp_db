#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker is not running."
  exit 1
fi

CORES="${1:-2}"

mkdir -p results/database results/analysis results/metadata results/reports work logs

docker compose -f env/docker-compose.yml run --rm snakemake \
  snakemake --snakefile Snakefile --configfile config/config.yaml --cores "${CORES}" --printshellcmds
