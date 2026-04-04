import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import '../services/health_calculator.dart';
import '../theme/app_theme.dart';

class HealthAnalyticsWidget extends StatelessWidget {
  final List<TreeRecord> trees;
  final Function(HealthStatus?)? onFilterTap;

  const HealthAnalyticsWidget({
    super.key,
    required this.trees,
    this.onFilterTap,
  });

  Map<String, dynamic> _calculateAnalytics() {
    if (trees.isEmpty) {
      return {
        'survivalRate': 0.0,
        'healthyCount': 0,
        'needsAttentionCount': 0,
        'criticalCount': 0,
        'newCount': 0,
        'avgDaysSinceUpdate': 0.0,
        'treesNeedingUpdate': 0,
      };
    }

    int healthyCount = 0;
    int needsAttentionCount = 0;
    int criticalCount = 0;
    int newCount = 0;
    int totalDays = 0;
    int treesNeedingUpdate = 0;

    for (final tree in trees) {
      final health = HealthCalculator.calculateHealth(tree);
      
      switch (health.status) {
        case HealthStatus.healthy:
          healthyCount++;
          break;
        case HealthStatus.needsAttention:
          needsAttentionCount++;
          break;
        case HealthStatus.critical:
          criticalCount++;
          break;
        case HealthStatus.newPlantation:
          newCount++;
          break;
      }

      totalDays += health.daysSinceUpdate;
      
      if (health.daysSinceUpdate >= 30) {
        treesNeedingUpdate++;
      }
    }

    final survivalRate = ((healthyCount + needsAttentionCount) / trees.length) * 100;
    final avgDaysSinceUpdate = totalDays / trees.length;

    return {
      'survivalRate': survivalRate,
      'healthyCount': healthyCount,
      'needsAttentionCount': needsAttentionCount,
      'criticalCount': criticalCount,
      'newCount': newCount,
      'avgDaysSinceUpdate': avgDaysSinceUpdate,
      'treesNeedingUpdate': treesNeedingUpdate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _calculateAnalytics();
    final survivalRate = analytics['survivalRate'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Health Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Survival Rate (big metric)
          Center(
            child: Column(
              children: [
                Text(
                  '${survivalRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    foreground: Paint()
                      ..shader = AppTheme.gradientPrimary.createShader(
                        const Rect.fromLTWH(0, 0, 200, 70),
                      ),
                  ),
                ),
                const Text(
                  'Survival Rate',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Health distribution
          _buildHealthBar(
            analytics['healthyCount'] as int,
            analytics['needsAttentionCount'] as int,
            analytics['criticalCount'] as int,
            analytics['newCount'] as int,
          ),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _statItem(
                  '${analytics['avgDaysSinceUpdate'].toStringAsFixed(0)}',
                  'Avg Days Since Update',
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  '${analytics['treesNeedingUpdate']}',
                  'Need Update',
                  AppTheme.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(int healthy, int needsAttention, int critical, int newPlant) {
    final total = healthy + needsAttention + critical + newPlant;
    if (total == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Distribution (Tap to filter)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (healthy > 0)
                Expanded(
                  flex: healthy,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFilterTap?.call(HealthStatus.healthy);
                    },
                    child: Container(
                      height: 12,
                      color: HealthCalculator.getHealthColor(HealthStatus.healthy),
                    ),
                  ),
                ),
              if (needsAttention > 0)
                Expanded(
                  flex: needsAttention,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFilterTap?.call(HealthStatus.needsAttention);
                    },
                    child: Container(
                      height: 12,
                      color: HealthCalculator.getHealthColor(HealthStatus.needsAttention),
                    ),
                  ),
                ),
              if (critical > 0)
                Expanded(
                  flex: critical,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFilterTap?.call(HealthStatus.critical);
                    },
                    child: Container(
                      height: 12,
                      color: HealthCalculator.getHealthColor(HealthStatus.critical),
                    ),
                  ),
                ),
              if (newPlant > 0)
                Expanded(
                  flex: newPlant,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFilterTap?.call(HealthStatus.newPlantation);
                    },
                    child: Container(
                      height: 12,
                      color: HealthCalculator.getHealthColor(HealthStatus.newPlantation),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem('Healthy', healthy, HealthCalculator.getHealthColor(HealthStatus.healthy), HealthStatus.healthy),
            _legendItem('Needs Attention', needsAttention, HealthCalculator.getHealthColor(HealthStatus.needsAttention), HealthStatus.needsAttention),
            _legendItem('Critical', critical, HealthCalculator.getHealthColor(HealthStatus.critical), HealthStatus.critical),
            _legendItem('New', newPlant, HealthCalculator.getHealthColor(HealthStatus.newPlantation), HealthStatus.newPlantation),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, int count, Color color, HealthStatus status) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onFilterTap?.call(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
