import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:well_being/app_barchart.dart';

import 'DailyActivityModel.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  DateTime currentDate = DateTime.now();
  DailyActivityModel? dailyActivity;

  List<Map<String, dynamic>>? weeklyData;

  static const platform = MethodChannel('com.flutter.well_being/stats');

  Future<void> _getDailyUsageStats(DateTime date) async {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    try {
      final result = await platform.invokeMethod('getDailyUsageStats', {
        'date': formattedDate,
      });
      debugPrint("RESULT: $result");

      if (result != null && result is List) {
        final parsedList = result
            .map((item) => ApplicationUsageModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        setState(() {
          dailyActivity = DailyActivityModel(
            date: formattedDate,
            applicationUsageList: parsedList,
          );
        });
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
  }


  Future<void> _getWeeklyUsageStats() async {
    try {
      final result = await platform.invokeMethod('getWeeklyUsageStats');
      debugPrint("Weekly data : $result");

      if (result != null && result is List) {
        final parsedList = result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        setState(() {
          weeklyData = parsedList;
        });
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
  }


  String formatDuration(int milliseconds) {
    final totalMinutes = (milliseconds / 60000).floor();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}hr ${minutes}mins';
    } else if (hours > 0) {
      return '${hours} hours';
    } else {
      return '${minutes} minutes';
    }
  }

  @override
  void initState() {
    super.initState();
    _getDailyUsageStats(currentDate);
    _getWeeklyUsageStats();
  }

  int getTotalDuration() {
    if (dailyActivity == null) return 0;
    return dailyActivity!.applicationUsageList.fold(
      0,
      (sum, app) => sum + app.usageDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = DateFormat('EEE, dd MMM').format(currentDate);
    final totalUsage = getTotalDuration();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Activity Details",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              spacing: 20,
              children: [
                Text(
                  formatDuration(totalUsage),
                  style: TextStyle(color: Colors.white, fontSize: 34),
                ),

                weeklyData == null
                    ? CircularProgressIndicator()
                    : AspectRatio(
                  aspectRatio: 2,
                  child: Appbarchart(weeklyData: weeklyData!)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentDate = currentDate.subtract(
                            const Duration(days: 1),
                          );
                          _getDailyUsageStats(currentDate);
                        });
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    Text(
                      formattedTitle,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () {
                        if (!isToday(currentDate)) {
                          setState(() {
                            currentDate = currentDate.add(
                              const Duration(days: 1),
                            );
                            _getDailyUsageStats(currentDate);
                          });
                        }
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                dailyActivity == null
                    ? CircularProgressIndicator()
                    : ListView.builder(
                        itemCount: dailyActivity!.applicationUsageList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final app =
                              dailyActivity!.applicationUsageList[index];
                          final totalMinutes = (app.usageDuration / 60000)
                              .floor();

                          if (totalMinutes <= 0) return const SizedBox.shrink();
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 5),
                            title: Text(
                              app.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              formatDuration(app.usageDuration),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(app.appLogo),
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.hourglass_bottom,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
