import '../models/tree_model.dart';

class ImpactCalculator {
  /// Standard young tree offsets roughly 20kg of CO2 per year.
  /// This breaks down to ~0.054 kg per day.
  static const double _dailyOffsetPerTree = 0.054;

  static double calculateTotalCo2(List<TreeRecord> trees) {
    double totalCo2 = 0;
    final now = DateTime.now();

    for (var tree in trees) {
      final plantDate = DateTime.tryParse(tree.dateTime);
      if (plantDate == null) continue;

      final daysSincePlanting = now.difference(plantDate).inDays;
      // Minimum 1 day to show some impact immediately
      final activeDays = daysSincePlanting > 0 ? daysSincePlanting : 1;
      
      totalCo2 += activeDays * _dailyOffsetPerTree;
    }

    return totalCo2;
  }

  static String formatCo2(double co2) {
    if (co2 >= 1000) {
      return '${(co2 / 1000).toStringAsFixed(2)} Tons';
    }
    return '${co2.toStringAsFixed(1)} kg';
  }
}
