import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class Appbarchart extends StatefulWidget {
  Appbarchart({super.key});

  @override
  State<Appbarchart> createState() => _AppbarchartState();
}

class _AppbarchartState extends State<Appbarchart> {
  final List<double> appData = [1, 2 , 4, 3.4, 2.3, 1.4, 2.5];





  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: const BarTouchData(enabled: false),
        titlesData: titlesData,
        borderData: FlBorderData(show: false),
        barGroups: getBarGroups(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white24, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        alignment: BarChartAlignment.spaceAround,
        maxY: 6,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(y: 0, color: Colors.white24, strokeWidth: 1),
            HorizontalLine(y: 6, color: Colors.white24, strokeWidth: 1),

          ]
        )
      ),
    );
  }

  List<BarChartGroupData> getBarGroups() {
    List<BarChartGroupData> barChartGroupData = appData
        .asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value,
            color: Colors.white,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 2,
              color: Colors.white10,
            ),
          ),
        ],
      );
    }).toList();

    return barChartGroupData;
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return Text(
            days[value.toInt()],
            style: TextStyle(color: Colors.white, fontSize: 12),
          );
        },
      ),
    ),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 2,
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}h',
            style: TextStyle(color: Colors.white, fontSize: 12),
          );
        },
      ),
    ),
  );
}
