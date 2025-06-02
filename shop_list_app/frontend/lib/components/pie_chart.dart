import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

Widget buildPieChart(Map<String, double> data) {
  final total = data.values.fold(0.0, (a, b) => a + b);

  if (total == 0) {
    return const Center(child: Text('No spending this month.'));
  }

  final List<PieChartSectionData> sections = data.entries.map((entry) {
    final percentage = (entry.value / total) * 100;
    return PieChartSectionData(
      color: getCategoryColor(entry.key),
      value: entry.value,
      title: '${percentage.toStringAsFixed(0)}%',
      //title: '${entry.value.toStringAsFixed(0)} RON',
      radius: 60,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }).toList();

  return Column(
    children: [
      SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 35,
            sectionsSpace: 2,
            startDegreeOffset: -90,
          ),
          swapAnimationDuration: const Duration(milliseconds: 500),
          swapAnimationCurve: Curves.easeInOut,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: data.keys.map((category) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: getCategoryColor(category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          );
        }).toList(),
      ),
    ],
  );
}

Color getCategoryColor(String? category) {
  switch (category) {
    case 'Meat':
      return const Color(0xFFEF9A9A);
    case 'Fruit':
      return const Color(0xFFA5D6A7);
    case 'Vegetable':
      return const Color(0xFFC5E1A5);
    case 'Cleaning':
      return const Color(0xFFFFE082);
    case 'Drink':
      return const Color(0xFF81D4FA);
    case 'Snack':
      return const Color(0xFFD7CCC8);
    case 'Food':
      return const Color(0xFFCE93D8);
    default:
      return Colors.grey.shade400;
  }
}
