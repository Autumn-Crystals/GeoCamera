import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import 'health_calculator.dart';

class ClusteringService {
  // Clustering constants
  static const double clusteringZoomThreshold = 12.0;
  static const double baseClusteringDistance = 0.01; // degrees

  // Grid cell for clustering
  static String _getGridCell(double lat, double lng, double cellSize) {
    final cellX = (lng / cellSize).floor();
    final cellY = (lat / cellSize).floor();
    return '${cellX}_$cellY';
  }

  // Calculate cell size based on zoom level
  static double _calculateCellSize(double zoom) {
    // Smaller cells at higher zoom levels
    const baseSize = 0.1;
    return baseSize / (1 << (zoom.toInt() - 5).clamp(0, 10));
  }

  // Cluster trees based on zoom level
  static List<MapItem> clusterTrees(
    List<TreeRecord> trees,
    double currentZoom,
  ) {
    // No clustering if zoomed in enough
    if (currentZoom >= clusteringZoomThreshold) {
      return trees.map((tree) {
        final healthStatus = HealthCalculator.calculateHealth(tree);
        return IndividualTreeItem(
          tree: tree,
          healthStatus: healthStatus,
        );
      }).toList();
    }

    // Calculate grid cell size based on zoom
    final cellSize = _calculateCellSize(currentZoom);

    // Group trees into grid cells
    final Map<String, List<TreeRecord>> grid = {};

    for (final tree in trees) {
      final cell = _getGridCell(tree.latitude, tree.longitude, cellSize);
      grid.putIfAbsent(cell, () => []).add(tree);
    }

    // Convert grid cells to MapItems
    final List<MapItem> result = [];

    for (final treesInCell in grid.values) {
      if (treesInCell.length == 1) {
        // Single tree - no clustering needed
        final tree = treesInCell[0];
        final healthStatus = HealthCalculator.calculateHealth(tree);
        result.add(IndividualTreeItem(
          tree: tree,
          healthStatus: healthStatus,
        ));
      } else {
        // Multiple trees - create cluster
        final centerLat = treesInCell.map((t) => t.latitude).reduce((a, b) => a + b) / treesInCell.length;
        final centerLng = treesInCell.map((t) => t.longitude).reduce((a, b) => a + b) / treesInCell.length;
        final clusterColor = getClusterColor(treesInCell);

        result.add(ClusterItem(
          trees: treesInCell,
          center: LatLng(centerLat, centerLng),
          clusterColor: clusterColor,
        ));
      }
    }

    return result;
  }

  // Determine cluster color based on worst health status
  static Color getClusterColor(List<TreeRecord> trees) {
    HealthStatus worstStatus = HealthStatus.healthy;

    for (final tree in trees) {
      final status = HealthCalculator.calculateHealth(tree).status;

      // Critical is worst
      if (status == HealthStatus.critical) {
        worstStatus = HealthStatus.critical;
        break;
      }

      // Needs attention is second worst
      if (status == HealthStatus.needsAttention &&
          worstStatus != HealthStatus.critical) {
        worstStatus = HealthStatus.needsAttention;
      }

      // New plantation is third
      if (status == HealthStatus.newPlantation &&
          worstStatus == HealthStatus.healthy) {
        worstStatus = HealthStatus.newPlantation;
      }
    }

    return HealthCalculator.getHealthColor(worstStatus);
  }
}
