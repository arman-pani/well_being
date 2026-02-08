import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Appbarchart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const Appbarchart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final barData = convertToBarGroups(weeklyData);

    return BarChart(
      BarChartData(
        barTouchData: const BarTouchData(enabled: false),
        titlesData: titlesData,
        borderData: FlBorderData(show: false),
        barGroups: barData,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white24, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        alignment: BarChartAlignment.spaceAround,
        maxY: 8,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(y: 0, color: Colors.white24, strokeWidth: 1),
            HorizontalLine(y: 8, color: Colors.white24, strokeWidth: 1),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> convertToBarGroups(List<Map<String, dynamic>> input) {
    List<double> hoursPerDay = List.filled(7, 0.0);

    final formatter = DateFormat('dd-MM-yyyy');
    for (final item in input) {
      try {
        final dateStr = item['date'] ?? '';
        final durationMs = item['duration'] ?? 0;
        final date = formatter.parse(dateStr);
        final weekdayIndex = (date.weekday % 7);
        final hours = (durationMs / (1000 * 60 * 60));
        hoursPerDay[weekdayIndex] += hours;
      } catch (_) {
        continue;
      }
    }

    return hoursPerDay.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: double.parse(e.value.toStringAsFixed(2)),
            color: Colors.white,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 8,
              color: Colors.white10,
            ),
          ),
        ],
      );
    }).toList();
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          if (value.toInt() >= 0 && value.toInt() < 7) {
            return Text(
              days[value.toInt()],
              style: TextStyle(color: Colors.white, fontSize: 12),
            );
          } else {
            return const SizedBox.shrink();
          }
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
