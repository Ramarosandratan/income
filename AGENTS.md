# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What this is

Family budget manager: two Flutter apps sharing one Supabase backend.
- **`apps/desktop`** — the "master" (parent) app: allocates budgets, enters income/fixed
  expenses, consults every member's spending, views reports. Role = `master`.
- **`apps/mobile`** — the member app: sees own "remaining to spend", logs expenses, views
  own budgets/savings/alerts. Role = `member`.

The role lives on the user's `profiles.role`, not on the device. Which UI you see is a
convention; **actual data isolation is enforced server-side by Postgres Row Level Security**
(`supabase/migrations/0003_rls.sql`), not in Dart.

## Toolchain & environment

Flutter is installed at `C:\Users\ramar\flutter` (not on bash PATH). Invoke via full path:
`C:\Users\ramar\flutter\bin\flutter.bat` / `dart.bat` (or `flutter`/`dart` in a fresh shell —
it's on the user PATH). Flutter 3.44 / Dart 3.12.

**Builds/runs are blocked on this machine**: Windows Defender refuses to execute the SDK's
unsigned `impellerc.exe` (shader compiler), so every `flutter build`/`run`/`test` fails at the
asset step — *not* a code problem. Verify code with `flutter analyze` and `dart test`, which
don't invoke impellerc. To actually build, an admin must run
`Add-MpPreference -ExclusionPath "C:\Users\ramar\flutter"` once, plus enable Windows Developer
Mode (plugin symlinks) and install the Android SDK (mobile). See README.md → "Configuration de
l'environnement".

## Commands

```powershell
flutter pub get                  # run at REPO ROOT — this is a pub workspace, one lockfile
flutter analyze                  # whole workspace; this is the primary correctness gate
dart test                        # run inside packages/core for pure-logic tests

# Single test (filter by name):
#   cd packages/core; dart test --name "reste à dépenser"

# Run apps (loads .env via --dart-define-from-file):
pwsh scripts/run-desktop.ps1                 # -Device chrome|windows
pwsh scripts/run-mobile.ps1

# Melos task aliases (analyze/test/format/run:desktop/run:mobile):
melos run analyze
```

`packages/core` tests use **`package:test` + direct `src/` imports**, NOT `flutter_test`. This
is deliberate: it keeps business-logic tests runnable via `dart test` (no Flutter engine, so no
impellerc). Don't switch them to `flutter_test`.

## Supabase backend

```powershell
supabase start        # local stack (needs Docker)
supabase db reset     # applies migrations 0001-0004 + seed.sql
supabase functions serve
```

Migrations are ordered and meaningful:
- `0001_schema.sql` — tables + enums.
- `0002_functions.sql` — `SECURITY DEFINER` helpers `auth_family_id()` / `auth_is_master()`
  (used by every RLS policy to avoid recursion), the `bootstrap_family` RPC (first signup
  creates family + master profile + default categories), `copy_budgets_to_next_month`,
  `add_savings_contribution`, and the **`check_budget_alert` trigger** (inserts an `alerts` row
  at 80%/100% of a member's monthly envelope).
- `0003_rls.sql` — the access model. Master = full access within `family_id`; member =
  read/write own `expenses`, read-only own budgets/categories.
- `0004_realtime.sql` — adds `expenses`/`alerts`/`budgets` to the realtime publication (the
  mobile app streams these).

`config.toml` runs auth with `enable_confirmations = false` for local dev.

## Architecture (the parts that span files)

**Dependency flow:** both apps depend on `packages/core`; nothing depends on the apps.
`income_core.dart` is the single barrel export — import that, not `src/`.

**Data access pattern:** `SupabaseClient` → one repository per table
(`packages/core/lib/src/repositories/`) → exposed as Riverpod providers in
`packages/core/lib/src/providers.dart`. Repos return domain models (`src/models/`), each with
`fromJson` + a `toInsert`/`toUpsert` that maps camelCase ↔ snake_case columns. Write conversion
logic in the model, not in screens.

**Budget math is pure and shared:** `BudgetCalculator` (`src/services/budget_calculator.dart`)
takes budgets + expenses and produces `MemberBudgetSummary`/`BudgetLine`. A budget with
`categoryId == null` is the "global envelope" covering expenses not matched by a categorized
envelope. `isExceeded` requires `allocated > 0` (overspending against a zero budget is not a
"dépassement"). This is the one piece with unit tests — keep it I/O-free.

**Period model:** a budget month is a `date` pinned to the 1st (`Period` util,
`src/utils/period.dart`). UI period selection is the shared `selectedPeriodProvider`; most
period-bound providers `ref.watch` it.

**App-side state:** each app has a `data.dart` of feature providers built on core's providers.
- Desktop aggregates the whole family (`memberSummariesProvider`); mutations call the
  local `refreshAll(ref)` helper to invalidate dependents.
- Mobile is member-scoped and prefers **realtime streams** (`myExpensesStreamProvider`,
  `myAlertsProvider`) so the dashboard/alerts update live; `mySummaryProvider` derives the
  "remaining to spend" by feeding the stream + budgets into `BudgetCalculator`.

**Routing/auth:** `go_router` per app, with a `redirect` driven by `authServiceProvider`
(login gate) and a `GoRouterRefreshStream` wrapping `onAuthStateChange`. `currentProfileProvider`
loads the signed-in `profiles` row (role + family).

**Config injection:** `SupabaseConfig` reads `SUPABASE_URL`/`SUPABASE_ANON_KEY` via
`String.fromEnvironment` — supplied by `--dart-define-from-file=.env`. It throws on startup if
unset.

**Member creation** can't happen client-side (needs the service-role key), so the master invites
via the `invite-member` Edge Function, called through `ProfileRepository.inviteMember`.

## Conventions

- UI is French; keep user-facing strings and comments in French to match.
- Category `icon`/`color` are stored as strings; convert with `CategoryVisuals`
  (`src/utils/category_visuals.dart`) — both apps rely on it.
- Money/date formatting goes through `Money` and `Period` (locale `fr_FR`).
