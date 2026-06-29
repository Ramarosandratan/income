/// income_core — modèles, accès données (Supabase) et logique métier partagés
/// par l'app mobile (membre) et l'app desktop (maître).
library;

// Modèles
export 'src/models/alert.dart';
export 'src/models/budget.dart';
export 'src/models/budget_summary.dart';
export 'src/models/calendrier/action_override.dart';
export 'src/models/calendrier/depense.dart';
export 'src/models/calendrier/depense_override.dart';
export 'src/models/calendrier/frequence.dart';
export 'src/models/calendrier/nature_montant.dart';
export 'src/models/calendrier/occurrence_resolu.dart';
export 'src/models/category.dart';
export 'src/models/enums.dart';
export 'src/models/expense.dart';
export 'src/models/family.dart';
export 'src/models/income.dart';
export 'src/models/profile.dart';
export 'src/models/recurring_template.dart';
export 'src/models/savings_goal.dart';

// Repositories
export 'src/repositories/alert_repository.dart';
export 'src/repositories/budget_repository.dart';
export 'src/repositories/category_repository.dart';
export 'src/repositories/expense_repository.dart';
export 'src/repositories/income_repository.dart';
export 'src/repositories/profile_repository.dart';
export 'src/repositories/recurring_repository.dart';
export 'src/repositories/savings_repository.dart';

// Services
export 'src/services/auth_service.dart';
export 'src/services/budget_calculator.dart';
export 'src/services/calendar_engine.dart';

// Supabase
export 'src/supabase/supabase_config.dart';

// Utils
export 'src/utils/category_visuals.dart';
export 'src/utils/money.dart';
export 'src/utils/period.dart';

// Providers Riverpod
export 'src/providers.dart';
