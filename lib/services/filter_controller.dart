import 'package:flutter/foundation.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import 'health_calculator.dart';

class FilterController extends ChangeNotifier {
  FilterMode _currentFilter = FilterMode.showAll;

  FilterMode get currentFilter => _currentFilter;

  // Set filter mode and notify listeners
  void setFilter(FilterMode mode) {
    if (_currentFilter != mode) {
      _currentFilter = mode;
      notifyListeners();
    }
  }

  // Apply filter to tree list
  List<TreeRecord> applyFilter(List<TreeRecord> trees) {
    if (_currentFilter == FilterMode.showAll) {
      return trees;
    }

    return trees.where((tree) {
      final healthStatus = HealthCalculator.calculateHealth(tree);

      switch (_currentFilter) {
        case FilterMode.healthyOnly:
          return healthStatus.status == HealthStatus.healthy;
        case FilterMode.needsAttentionOnly:
          return healthStatus.status == HealthStatus.needsAttention;
        case FilterMode.criticalOnly:
          return healthStatus.status == HealthStatus.critical;
        case FilterMode.showAll:
          return true;
      }
    }).toList();
  }

  // Get health counts for all trees
  Map<HealthStatus, int> getHealthCounts(List<TreeRecord> trees) {
    final counts = <HealthStatus, int>{
      HealthStatus.healthy: 0,
      HealthStatus.needsAttention: 0,
      HealthStatus.critical: 0,
      HealthStatus.newPlantation: 0,
    };

    for (final tree in trees) {
      final healthStatus = HealthCalculator.calculateHealth(tree);
      counts[healthStatus.status] = (counts[healthStatus.status] ?? 0) + 1;
    }

    return counts;
  }
}
