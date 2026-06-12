# Lance l'app mobile (membre). Charge les variables Supabase depuis .env (racine).
# Usage : pwsh scripts/run-mobile.ps1 [-Device <id>]
# (laissez vide pour laisser Flutter choisir l'appareil/émulateur connecté)
param([string]$Device = '')

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) {
  Write-Error "Fichier .env introuvable. Copiez .env.example en .env et remplissez-le."
  exit 1
}

Push-Location (Join-Path $root 'apps/mobile')
if ($Device) {
  flutter run -d $Device --dart-define-from-file="$envFile"
} else {
  flutter run --dart-define-from-file="$envFile"
}
Pop-Location
