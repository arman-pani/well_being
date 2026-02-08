class DailyActivityModel {
  final String date;
  final List<ApplicationUsageModel> applicationUsageList;

  DailyActivityModel({required this.date, required this.applicationUsageList});

  factory DailyActivityModel.fromJson(Map<String, dynamic> json) {
    return DailyActivityModel(
      date: json['date'],
      applicationUsageList: (json['applicationUsageList'] as List)
          .map((item) => ApplicationUsageModel.fromJson(item))
          .toList(),
    );
  }
}

class ApplicationUsageModel {
  final String name;
  final String appLogo;
  final int usageDuration;

  ApplicationUsageModel({
    required this.name,
    required this.appLogo,
    required this.usageDuration,
  });

  factory ApplicationUsageModel.fromJson(Map<String, dynamic> json) {
    return ApplicationUsageModel(
      name: json['packageName']?.toString() ?? 'Unknown App',
      appLogo: json['packageLogo']?.toString() ?? '',
      usageDuration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
