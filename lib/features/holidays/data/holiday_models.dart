class HolidayItem {
  const HolidayItem({
    required this.id,
    required this.name,
    required this.date,
    required this.dayOfWeek,
    required this.holidayType,
    this.description,
    required this.isOptional,
    required this.isPast,
  });

  final int id;
  final String name;
  final String date;
  final String dayOfWeek;
  final String holidayType; // national, festival, company, optional
  final String? description;
  final bool isOptional;
  final bool isPast;

  factory HolidayItem.fromJson(Map<String, dynamic> json) {
    return HolidayItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      date: json['date'] as String,
      dayOfWeek: json['day_of_week'] as String? ?? '',
      holidayType: json['holiday_type'] as String? ?? 'company',
      description: json['description'] as String?,
      isOptional: json['is_optional'] as bool? ?? false,
      isPast: json['is_past'] as bool? ?? false,
    );
  }
}
