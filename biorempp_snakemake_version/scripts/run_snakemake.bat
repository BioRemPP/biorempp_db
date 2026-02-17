@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0.."

docker info >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker is not running.
  exit /b 1
)

set CORES=2
if not "%~1"=="" set CORES=%~1

if not exist results\database mkdir results\database
if not exist results\analysis mkdir results\analysis
if not exist results\metadata mkdir results\metadata
if not exist results\reports mkdir results\reports
if not exist work mkdir work
if not exist logs mkdir logs

docker compose -f env\docker-compose.yml run --rm snakemake ^
  snakemake --snakefile Snakefile --configfile config/config.yaml --cores %CORES% --printshellcmds

if errorlevel 1 exit /b 1

echo Pipeline completed successfully.
