import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/holiday_models.dart';
import '../data/holiday_repository.dart';

final holidaysProvider = FutureProvider.family<List<HolidayItem>, int?>((ref, year) async {
  return ref.watch(holidayRepositoryProvider).getHolidays(year: year);
});

final upcomingHolidaysProvider = FutureProvider.autoDispose<List<HolidayItem>>((ref) async {
  return ref.watch(holidayRepositoryProvider).getHolidays(upcoming: true);
});
