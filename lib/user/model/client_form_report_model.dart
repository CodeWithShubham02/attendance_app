class ClientFormReportModel {
  final int id;
  final int uid;
  final String userId;
  final String userName;
  final String cityName;
  final String reportDate;
  final String reportTime;
  final String applicationNo;
  final String relation;
  final String variant;
  final String status;
  final String remarks;
  final String contactNo;
  final List<String> imageUrls;
  final String gpsLocation;
  final String kioskName;
  final String createdAt;
  final String updatedAt;
  final String duplicateFrom;

  ClientFormReportModel({
    required this.id,
    required this.uid,
    required this.userId,
    required this.userName,
    required this.cityName,
    required this.reportDate,
    required this.reportTime,
    required this.applicationNo,
    required this.relation,
    required this.variant,
    required this.status,
    required this.remarks,
    required this.contactNo,
    required this.imageUrls,
    required this.gpsLocation,
    required this.kioskName,
    required this.createdAt,
    required this.updatedAt,
    required this.duplicateFrom,
  });

  factory ClientFormReportModel.fromJson(Map<String, dynamic> json) {
    return ClientFormReportModel(
      id: int.parse(json['id'].toString()),
      uid: int.parse(json['uid'].toString()),
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      cityName: json['city_name'] ?? '',
      reportDate: json['report_date'] ?? '',
      reportTime: json['report_time'] ?? '',
      applicationNo: json['application_no'] ?? '',
      relation: json['relation'] ?? '',
      variant: json['variant'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      contactNo: json['contact_no'] ?? '',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      gpsLocation: json['gps_location'] ?? '',
      kioskName: json['kiosk_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      duplicateFrom: json['duplicate_from'] ?? 'no',
    );
  }
}
