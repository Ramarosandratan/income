void main() {
  // Simulate the _prochainJourSemaine function
  DateTime prochainJourSemaine(DateTime now, int targetWeekday) {
    final diff = (targetWeekday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + diff);
  }

  // Simulate the _prochainJourMois function
  DateTime prochainJourMois(DateTime now, int targetDay) {
    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final clamped = targetDay.clamp(1, lastDayThisMonth);
    if (now.day <= clamped) {
      return DateTime(now.year, now.month, clamped);
    }
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDayNext = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(nextMonth.year, nextMonth.month, targetDay.clamp(1, lastDayNext));
  }

  // Test: what day is June 29, 2026?
  final testDate = DateTime(2026, 6, 29);
  print('June 29, 2026 is day ${testDate.weekday} (1=Mon, 7=Sun)');

  // Test _prochainJourSemaine with today = June 29
  print('\n--- _prochainJourSemaine ---');
  for (final target in [1, 2, 3, 4, 5, 6, 7]) {
    final result = prochainJourSemaine(testDate, target);
    print('  target=$target (${['','Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][target]}) → ${result.day}/${result.month}/${result.year} (day ${result.weekday})');
  }

  // Test _prochainJourMois with today = June 15
  final testDate2 = DateTime(2026, 6, 15);
  print('\n--- _prochainJourMois (today=June 15) ---');
  for (final target in [5, 15, 20, 31]) {
    final result = prochainJourMois(testDate2, target);
    print('  target=$target → ${result.day}/${result.month}/${result.year}');
  }

  // Test _prochainJourMois with today = June 29
  print('\n--- _prochainJourMois (today=June 29) ---');
  for (final target in [5, 15, 20, 31]) {
    final result = prochainJourMois(testDate, target);
    print('  target=$target → ${result.day}/${result.month}/${result.year}');
  }
}
