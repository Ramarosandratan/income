-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Index sur alerts.period pour optimiser la déduplication             ║
-- ╚══════════════════════════════════════════════════════════════════════╝

create index if not exists alerts_period_idx on public.alerts (period);
