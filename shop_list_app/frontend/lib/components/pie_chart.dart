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
      title: '${entry.key} (${percentage.toStringAsFixed(1)}%)',
      radius: 80,
      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }).toList();

  return PieChart(
    PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
    ),
  );
}

Color getCategoryColor(String category) {
  switch (category) {
    case 'Food':
      return Colors.green;
    case 'Drinks':
      return Colors.blue;
    case 'Household':
      return Colors.orange;
    case 'Electronics':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}
