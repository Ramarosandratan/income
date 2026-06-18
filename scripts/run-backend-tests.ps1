# Tests d'intégration backend, hermétiques : monte un cluster PostgreSQL jetable
# (sans Docker ni droits admin), applique 00_auth_shim + migrations + 01_grants +
# seed, lance supabase/tests/integration_test.sql, puis détruit le cluster.
#
# Prérequis : PostgreSQL installé (binaires initdb/pg_ctl/psql). Aucun serveur
# en cours d'exécution n'est requis.
#
# Usage : pwsh scripts/run-backend-tests.ps1
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$port = 55432
$cluster = Join-Path $env:TEMP 'income_pgtest'

# 1. Localiser les binaires PostgreSQL.
$bin = $null
$psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlCmd) { $bin = Split-Path $psqlCmd.Source }
if (-not $bin) {
  $candidate = Get-ChildItem 'C:\Program Files\PostgreSQL' -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
  if ($candidate) { $bin = Join-Path $candidate.FullName 'bin' }
}
if (-not $bin -or -not (Test-Path (Join-Path $bin 'initdb.exe'))) {
  Write-Error "PostgreSQL introuvable. Installez-le ou ajoutez ses binaires au PATH."
  exit 1
}
$initdb = Join-Path $bin 'initdb.exe'
$pg_ctl = Join-Path $bin 'pg_ctl.exe'
$psql   = Join-Path $bin 'psql.exe'

function Stop-Cluster {
  if (Test-Path $cluster) {
    & $pg_ctl -D $cluster stop -m immediate 2>$null | Out-Null
    Remove-Item $cluster -Recurse -Force -ErrorAction SilentlyContinue
  }
}

try {
  Stop-Cluster
  Write-Host "→ Création du cluster jetable…"
  & $initdb -D $cluster -U postgres -A trust --encoding=UTF8 | Out-Null
  & $pg_ctl -D $cluster -o "-p $port" -l (Join-Path $cluster 'log.txt') start | Out-Null
  Start-Sleep -Seconds 2

  $run = { param($db, $file)
    & $psql -U postgres -h 127.0.0.1 -p $port -d $db -q -v ON_ERROR_STOP=1 -f $file
    if ($LASTEXITCODE -ne 0) { throw "Échec sur $file" }
  }

  & $psql -U postgres -h 127.0.0.1 -p $port -d postgres -q -c "create database income_test;" | Out-Null

  $files = @(
    (Join-Path $root 'supabase/tests/00_auth_shim.sql')
  ) + (Get-ChildItem (Join-Path $root 'supabase/migrations') -Filter '*.sql' | Sort-Object Name | ForEach-Object FullName) + @(
    (Join-Path $root 'supabase/tests/01_grants.sql'),
    (Join-Path $root 'supabase/seed.sql')
  )
  foreach ($f in $files) { & $run 'income_test' $f }

  Write-Host "→ Exécution des tests d'intégration…`n"
  & $psql -U postgres -h 127.0.0.1 -p $port -d income_test -v ON_ERROR_STOP=1 `
      -f (Join-Path $root 'supabase/tests/integration_test.sql') 2>&1 |
    Select-String -Pattern 'OK —|TOUS LES TESTS|exception|ERROR|FATAL' | ForEach-Object { $_.Line }
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "Tests d'intégration en échec (code $code)" }
  Write-Host "`n✅ Suite backend : tout est vert."
}
finally {
  Stop-Cluster
}
