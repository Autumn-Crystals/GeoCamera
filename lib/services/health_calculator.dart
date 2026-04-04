import 'package:flutter/material.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import '../theme/app_theme.dart';

class HealthCalculator {
  // Calculate health status for a tree based on updates and time elapsed
  static TreeHealthStatus calculateHealth(TreeRecord tree) {
    final currentDate = DateTime.now();

    // Case 1: No updates yet (new plantation)
    if (tree.updates.isEmpty) {
      final plantDate = DateTime.tryParse(tree.dateTime);
      final daysSincePlant = plantDate != null
          ? currentDate.difference(plantDate).inDays
          : 0;

      return TreeHealthStatus(
        status: HealthStatus.newPlantation,
        color: getHealthColor(HealthStatus.newPlantation),
        reason: 'New plantation, no updates yet',
        daysSinceUpdate: daysSincePlant,
      );
    }

    // Case 2: Has updates - analyze latest update
    final latestUpdate = tree.updates.last;
    final updateDate = DateTime.tryParse(latestUpdate.dateTime);
    final daysSinceUpdate = updateDate != null
        ? currentDate.difference(updateDate).inDays
        : 0;

    HealthStatus status;
    String reason;

    // Determine status based on condition and time
    final condition = latestUpdate.condition.toLowerCase();

    if (condition == 'poor' || daysSinceUpdate >= 60) {
      status = HealthStatus.critical;
      if (condition == 'poor') {
        reason = 'Poor condition reported';
      } else {
        reason = 'Critically overdue for update (60+ days)';
      }
    } else if (condition == 'moderate' || daysSinceUpdate >= 30) {
      status = HealthStatus.needsAttention;
      if (condition == 'moderate') {
        reason = 'Moderate condition';
      } else {
        reason = 'Needs update (30+ days since last check)';
      }
    } else if (condition == 'good' && daysSinceUpdate < 30) {
      status = HealthStatus.healthy;
      reason = 'Good condition, recently updated';
    } else {
      // Default to healthy
      status = HealthStatus.healthy;
      reason = 'Healthy';
    }

    return TreeHealthStatus(
      status: status,
      color: getHealthColor(status),
      reason: reason,
      daysSinceUpdate: daysSinceUpdate,
    );
  }

  // Map HealthStatus enum to Flutter Color objects
  static Color getHealthColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return AppTheme.primary; // Green
      case HealthStatus.needsAttention:
        return AppTheme.accent; // Yellow
      case HealthStatus.critical:
        return AppTheme.danger; // Red
      case HealthStatus.newPlantation:
        return AppTheme.textMuted; // Gray
    }
  }

  // Calculate days since last update
  static int getDaysSinceLastUpdate(TreeRecord tree) {
    final currentDate = DateTime.now();

    if (tree.updates.isEmpty) {
      final plantDate = DateTime.tryParse(tree.dateTime);
      return plantDate != null
          ? currentDate.difference(plantDate).inDays
          : 0;
    }

    final latestUpdate = tree.updates.last;
    final updateDate = DateTime.tryParse(latestUpdate.dateTime);
    return updateDate != null
        ? currentDate.difference(updateDate).inDays
        : 0;
  }
}
