import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'tree_model.dart';

// Health status enum for tree condition
enum HealthStatus {
  healthy,
  needsAttention,
  critical,
  newPlantation,
}

// Tree health status with color and metadata
class TreeHealthStatus {
  final HealthStatus status;
  final Color color;
  final String reason;
  final int daysSinceUpdate;

  TreeHealthStatus({
    required this.status,
    required this.color,
    required this.reason,
    required this.daysSinceUpdate,
  });
}

// Filter mode enum for map filtering
enum FilterMode {
  showAll,
  healthyOnly,
  needsAttentionOnly,
  criticalOnly,
}

// Abstract base class for map items (individual trees or clusters)
abstract class MapItem {
  LatLng get position;
  Color get color;
}

// Individual tree item for map display
class IndividualTreeItem extends MapItem {
  final TreeRecord tree;
  final TreeHealthStatus healthStatus;

  IndividualTreeItem({
    required this.tree,
    required this.healthStatus,
  });

  @override
  LatLng get position => LatLng(tree.latitude, tree.longitude);

  @override
  Color get color => healthStatus.color;
}

// Cluster item for grouped trees
class ClusterItem extends MapItem {
  final List<TreeRecord> trees;
  final LatLng center;
  final Color clusterColor;

  ClusterItem({
    required this.trees,
    required this.center,
    required this.clusterColor,
  });

  @override
  LatLng get position => center;

  @override
  Color get color => clusterColor;

  int get count => trees.length;
}
