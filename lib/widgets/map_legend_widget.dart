import 'package:flutter/material.dart';
import '../models/map_models.dart';
import '../services/health_calculator.dart';
import '../theme/app_theme.dart';

class MapLegendWidget extends StatefulWidget {
  final Map<HealthStatus, int> healthCounts;
  final bool initiallyExpanded;

  const MapLegendWidget({
    super.key,
    required this.healthCounts,
    this.initiallyExpanded = true,
  });

  @override
  State<MapLegendWidget> createState() => _MapLegendWidgetState();
}

class _MapLegendWidgetState extends State<MapLegendWidget>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildLegendItem(HealthStatus status, Color color, int count) {
    String label;
    switch (status) {
      case HealthStatus.healthy:
        label = 'Healthy';
        break;
      case HealthStatus.needsAttention:
        label = 'Needs Attention';
        break;
      case HealthStatus.critical:
        label = 'Critical';
        break;
      case HealthStatus.newPlantation:
        label = 'New Plantation';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle button
            InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Tree Health',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable legend items
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: AppTheme.divider),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      HealthStatus.healthy,
                      HealthCalculator.getHealthColor(HealthStatus.healthy),
                      widget.healthCounts[HealthStatus.healthy] ?? 0,
                    ),
                    _buildLegendItem(
                      HealthStatus.needsAttention,
                      HealthCalculator.getHealthColor(HealthStatus.needsAttention),
                      widget.healthCounts[HealthStatus.needsAttention] ?? 0,
                    ),
                    _buildLegendItem(
                      HealthStatus.critical,
                      HealthCalculator.getHealthColor(HealthStatus.critical),
                      widget.healthCounts[HealthStatus.critical] ?? 0,
                    ),
                    _buildLegendItem(
                      HealthStatus.newPlantation,
                      HealthCalculator.getHealthColor(HealthStatus.newPlantation),
                      widget.healthCounts[HealthStatus.newPlantation] ?? 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
