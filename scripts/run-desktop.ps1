# Lance l'app desktop (maître). Charge les variables Supabase depuis .env (racine).
# Usage : pwsh scripts/run-desktop.ps1 [-Device windows|chrome]
param([string]$Device = 'windows')

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) {
  Write-Error "Fichier .env introuvable. Copiez .env.example en .env et remplissez-le."
  exit 1
}

Push-Location (Join-Path $root 'apps/desktop')
flutter run -d $Device --dart-define-from-file="$envFile"
Pop-Location
