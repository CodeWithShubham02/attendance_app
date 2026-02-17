class AttendanceSummary {
  final int uid;
  final String name;
  final String department;
  final String officeName;
  final int totalDays;
  final int totalPresent;
  final int totalAbsent;
  // final int totalLate;
  final int totalHoliday;
  final int missedPunchOut;
  final int totalHour;
  final int totalGps;
  final int totalInternet;
  final int totalOutside;
  final String fromDate;
  final String toDate;

  AttendanceSummary({
    required this.uid,
    required this.name,
    required this.department,
    required this.officeName,
    required this.totalDays,
    required this.totalPresent,
    required this.totalAbsent,
    // required this.totalLate,
    required this.totalHoliday,
    required this.missedPunchOut,
    required this.totalHour,
    required this.totalGps,
    required this.totalInternet,
    required this.totalOutside,
    required this.fromDate,
    required this.toDate,
  });

  /// 🔥 SAFE NUM → INT CONVERTER
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      uid: _toInt(json['uid']),
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      officeName: json['office_name']?.toString() ?? '',
      totalDays: _toInt(json['total_days']),
      totalPresent: _toInt(json['total_present']),
      totalAbsent: _toInt(json['total_absent']),
      // totalLate: _toInt(json['total_late']),
      totalHoliday: _toInt(json['total_holiday']),
      missedPunchOut: _toInt(json['missed_punchOut']),
      totalHour: _toInt(json['total_hour']),
      totalGps: _toInt(json['gps_auto_count']),
      totalInternet: _toInt(json['internet_auto_count']),
      totalOutside: _toInt(json['outside_radius_count']),
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
    );
  }
}
