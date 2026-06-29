# QWEN.md — Income (Family Budget Manager)

## Project Overview

**Income** is a family budget management system built with Flutter (Dart 3.12 / Flutter 3.44). It consists of **two apps** sharing a **single backend** (Supabase) and a **shared core package**:

| Package | Role |
|---|---|
| `apps/desktop` | Master app — allocates budgets, enters income/fixed expenses, views all members' spending and reports |
| `apps/mobile` | Member app — logs expenses, views own budget/savings/alerts |
| `packages/core` | Shared domain models, repositories, services, and Riverpod providers |

Data isolation is enforced **server-side** via Postgres Row Level Security (`supabase/migrations/0003_rls.sql`), not in Dart. Roles are `master` and `member` on `profiles.role`.

## Architecture

```
apps/desktop ──┐
apps/mobile  ──┤──► packages/core ──► Supabase (Postgres + Auth + Realtime + RLS)
               ┘
```

**Key patterns:**
- **Data access:** `SupabaseClient` → one repository per table (`core/src/repositories/`) → Riverpod providers (`core/src/providers.dart`). Models handle `fromJson`/`toInsert`/`toUpsert` snake_case↔camelCase mapping.
- **Budget math:** `BudgetCalculator` (`core/src/services/budget_calculator.dart`) — pure logic, unit-tested, I/O-free. A zero budget is not "exceeded" even if spending > 0.
- **Period model:** Budget months are `date` pinned to the 1st (`Period` util, `core/src/utils/period.dart`). UI period selection via `selectedPeriodProvider`.
- **State management:** Riverpod + `go_router` per app. Desktop aggregates family-wide data; mobile uses realtime streams (`myExpensesStreamProvider`, `myAlertsProvider`).

## Building & Running

This is a **pub workspace** — run commands from the repo root:

```powershell
flutter pub get                  # one lockfile for the whole workspace
flutter analyze                  # primary correctness gate (0 issues)
dart test                        # run inside packages/core for pure-logic tests

# Run apps (loads .env via --dart-define-from-file):
pwsh scripts/run-desktop.ps1                 # -Device chrome|windows
pwsh scripts/run-mobile.ps1

# Melos aliases:
melos run analyze
melos run run:desktop
melos run run:mobile
```

### Supabase (local)

```powershell
supabase start                       # local stack (needs Docker)
supabase db reset                    # applies migrations 0001-0006 + seed.sql
supabase functions serve
```

### Environment (.env)

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### Build limitations on this machine

- **Windows Defender blocks `impellerc.exe`** (unsigned shader compiler) → `flutter build`/`run`/`test` fail at the asset step. Use `flutter analyze` and `dart test` for verification.
- To fix (admin required once): `Add-MpPreference -ExclusionPath "C:\Users\ramar\flutter"`
- Flutter SDK at `C:\Users\ramar\flutter` (on user PATH).

## Database Schema

Tables in order: `families` → `profiles` → `categories` → `incomes` → `budgets` → `expenses` → `recurring_templates` → `savings_goals` → `alerts`.

Migrations (`supabase/migrations/`):
- `0001_schema.sql` — all tables + enums
- `0002_functions.sql` — auth helpers (`auth_family_id`, `auth_is_master`), `bootstrap_family` RPC, `copy_budgets_to_next_month`, `check_budget_alert` trigger
- `0003_rls.sql` — access policies (master = full, member = own expenses read/write)
- `0004_realtime.sql` — realtime publication for expenses/alerts/budgets
- `0005_fixes.sql` — subsequent fixes
- `0006_income_frequency.sql` — income frequency support

## Conventions

- **UI language:** French — keep user-facing strings in French.
- **Imports:** use `income_core.dart` barrel (not `src/` directly) from apps.
- **Tests:** `packages/core` tests use `package:test` (not `flutter_test`) so they run via `dart test` without the Flutter engine.
- **Category visuals:** `icon`/`color` are strings; convert via `CategoryVisuals` (`core/src/utils/category_visuals.dart`).
- **Formatting:** money/dates through `Money` and `Period` (locale `fr_FR`).

## Key Files

| Path | Purpose |
|---|---|
| `packages/core/lib/income_core.dart` | Single barrel export for the shared package |
| `packages/core/lib/src/providers.dart` | All Riverpod providers (client, repos, auth, budget calc) |
| `packages/core/lib/src/services/budget_calculator.dart` | Pure budget math (unit-tested) |
| `apps/desktop/lib/main.dart` | Desktop entry point |
| `apps/desktop/lib/data.dart` | Desktop-specific feature providers |
| `apps/desktop/lib/router.dart` | Desktop routing with go_router |
| `supabase/migrations/` | Ordered SQL migrations |
