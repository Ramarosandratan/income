# Income — Gestion de budget familial

Application de gestion de budget pour une famille, en deux apps Flutter partageant un même
backend Supabase :

- **App mobile (membre)** — chaque membre voit son budget et saisit ses dépenses
  (journalières, mensuelles, fixes).
- **App desktop (maître)** — le compte administrateur distribue les budgets, saisit les
  revenus et dépenses fixes du foyer, et consulte les dépenses de chaque membre.

## Architecture

```
apps/mobile   ─┐
apps/desktop  ─┼─► packages/core ─► Supabase (Postgres + Auth + Realtime + RLS)
               ┘
```

- **Stack** : Flutter (mobile + Windows desktop), Dart, Riverpod, go_router, fl_chart.
- **Backend** : Supabase. Schéma et policies dans `supabase/migrations/`, tâches planifiées
  et déclencheurs dans `supabase/functions/`.
- **Monorepo** : pub workspaces + Melos.

## Prérequis

| Outil | Rôle | Installation |
|---|---|---|
| Flutter SDK ≥ 3.44 | build/run des apps | https://docs.flutter.dev/get-started/install/windows |
| Visual Studio 2022 + « Desktop development with C++ » | **requis** pour compiler l'app Windows | https://visualstudio.microsoft.com/ |
| Melos | scripts monorepo | `dart pub global activate melos` |
| Supabase CLI | backend local & migrations | `npm i -g supabase` ou https://supabase.com/docs/guides/cli |

> Le SDK Flutter peut être installé sans droits administrateur (extraction du zip). En
> revanche, **compiler l'app desktop Windows requiert Visual Studio avec la charge de travail
> C++** (installation administrateur). L'app mobile et l'analyse statique n'en ont pas besoin.

## Démarrage

```powershell
# 1. Configurer l'accès Supabase (copier puis remplir)
copy .env.example .env

# 2. Récupérer les dépendances de tout le workspace
flutter pub get

# 3. Générer les dossiers de plateforme (une seule fois, voir scripts/scaffold.ps1)
#    puis lancer :
melos run run:desktop     # app maître (Windows)
melos run run:mobile      # app membre (émulateur/appareil)
```

### Backend Supabase (local)

```powershell
supabase start                       # démarre Postgres + services en local (Docker)
supabase db reset                    # applique migrations + seed
supabase functions serve             # sert les Edge Functions
```

Les clés affichées par `supabase start` (API URL + anon key) vont dans `.env`.

## Configuration (.env)

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

Ces valeurs sont injectées au build via `--dart-define` (voir `packages/core`).

## Lancer les apps (scripts)

```powershell
# Charge automatiquement .env (--dart-define-from-file) :
pwsh scripts/run-desktop.ps1            # maître, sur Windows
pwsh scripts/run-desktop.ps1 -Device chrome
pwsh scripts/run-mobile.ps1             # membre, sur l'appareil/émulateur détecté
```

## État de vérification (au 2026-06-01)

Réalisé et vérifié dans cet environnement :
- `flutter analyze` sur tout le workspace : **0 problème**.
- Tests de logique métier (`dart test` dans `packages/core`) : **4/4 OK**.
- Compilation Dart de l'app desktop pour le web : **réussie** (le code compile
  intégralement ; voir la limite ci-dessous).

## Configuration de l'environnement & dépannage

Cette machine a Flutter 3.44.1, Dart 3.12.1 et **Visual Studio Community 2026**
(charge de travail Windows présente). Points à régler pour **compiler/lancer** :

1. **Windows Defender bloque `impellerc.exe`** (le compilateur de shaders du SDK).
   Comme le binaire est non signé et de faible réputation, la protection en temps
   réel refuse son exécution (« Accès refusé »), ce qui fait échouer **tout** build
   Flutter à l'étape des shaders. Correctif (droits admin requis, une fois) :
   ```powershell
   # PowerShell en administrateur :
   Add-MpPreference -ExclusionPath "C:\Users\ramar\flutter"
   ```
   (ou ajouter une exclusion de dossier dans Sécurité Windows → Protection contre
   les virus → Exclusions.)

2. **Mode développeur Windows** — requis pour les liens symboliques des plugins
   lors du build desktop :
   ```
   start ms-settings:developers   # puis activer « Mode développeur »
   ```

3. **App mobile (Android)** — l'Android SDK n'est pas installé. Installez Android
   Studio (qui pose le SDK + un émulateur), puis :
   ```powershell
   flutter config --android-sdk "<chemin du SDK>"
   flutter doctor --android-licenses
   ```

4. **Backend Supabase** — pour un lancement réel, démarrez Supabase en local
   (`supabase start`, nécessite Docker Desktop) ou utilisez un projet cloud, puis
   renseignez `.env`.

> Sans le correctif (1), vous pouvez tout de même valider le code via
> `flutter analyze` et `dart test` (qui n'invoquent pas `impellerc`).

## Rôles & sécurité

Le cloisonnement des données est garanti côté base par la **Row Level Security** :
- `master` : accès complet aux données de sa famille ;
- `member` : accès uniquement à ses propres dépenses, lecture seule de ses budgets.

Voir `supabase/migrations/` pour les policies.
