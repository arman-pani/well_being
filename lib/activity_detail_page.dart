import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:well_being/app_barchart.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {

  List<dynamic>? data;
  static const platform = MethodChannel('com.flutter.well_being/stats');
  Future<void> _getUsageStats() async {
    try {
      debugPrint("FETCHING USAGE STATS");
      final result = await platform.invokeMethod('getUsageStats');
      debugPrint("FLUTTER RESULT : $result");
      setState(() {
        data = result;
      });
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
    _getUsageStats();
  }
  @override
  Widget build(BuildContext context) {
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
                  "3 hrs, 50 mins",
                  style: TextStyle(color: Colors.white, fontSize: 34),
                ),

                AspectRatio(aspectRatio: 2, child: Appbarchart()),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    Text(
                      "Mon, 23 Jun",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                data == null ?
                CircularProgressIndicator() :
                ListView.builder(
                  itemCount: data?.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    final item = data![index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      title: Text(item['packageName'] ?? "NA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold) ),
                      subtitle: Text(formatDuration(item['totalTimeInForeground'])  ?? "NA", style: TextStyle(color: Colors.grey, fontSize: 14) ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(item['packageLogo'] ?? ""),
                          width: 40,
                          height: 40,
                        ),
                      ),
                      trailing: IconButton(onPressed: (){}, icon: Icon(Icons.hourglass_bottom, color: Colors.white,)),
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
}
