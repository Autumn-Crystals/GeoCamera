import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/tree_model.dart';
import '../services/health_calculator.dart';
import '../services/marker_generator.dart';
import '../services/clustering_service.dart';
import '../models/map_models.dart';
import '../theme/app_theme.dart';
import 'map_legend_widget.dart';

// Custom gesture recognizer to allow map gestures inside scrollable parent
class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class MapVisualizationWidget extends StatefulWidget {
  final List<TreeRecord> trees;
  final Function(String treeId) onTreeTap;

  const MapVisualizationWidget({
    super.key,
    required this.trees,
    required this.onTreeTap,
  });

  @override
  State<MapVisualizationWidget> createState() => _MapVisualizationWidgetState();
}

class _MapVisualizationWidgetState extends State<MapVisualizationWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  double _currentZoom = 12.0;
  Map<HealthStatus, int> _healthCounts = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(MapVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trees != widget.trees) {
      _updateMarkers();
    }
  }

  Future<void> _updateMarkers() async {
    final validTrees = widget.trees.where((t) =>
      t.latitude >= -90 && t.latitude <= 90 &&
      t.longitude >= -180 && t.longitude <= 180
    ).toList();

    if (validTrees.isEmpty) {
      setState(() {
        _markers = {};
        _healthCounts = {};
      });
      return;
    }

    // Calculate health counts
    final counts = <HealthStatus, int>{};
    for (final tree in validTrees) {
      final health = HealthCalculator.calculateHealth(tree);
      counts[health.status] = (counts[health.status] ?? 0) + 1;
    }

    // Apply clustering
    final items = ClusteringService.clusterTrees(validTrees, _currentZoom);
    
    // Generate markers for both individual trees and clusters
    final markers = <Marker>{};
    
    for (final item in items) {
      if (item is IndividualTreeItem) {
        // Generate marker for individual tree
        final tree = item.tree;
        final healthStatus = HealthCalculator.calculateHealth(tree);
        final markerSize = MarkerGenerator.calculateMarkerSize(tree.updates.length);
        final shouldPulse = healthStatus.status == HealthStatus.critical;

        final markerIcon = await MarkerGenerator.createCircularMarker(
          color: healthStatus.color,
          size: markerSize,
          shouldPulse: shouldPulse,
        );

        final plantDate = DateTime.tryParse(tree.dateTime);
        final dateStr = plantDate != null
            ? '${plantDate.day}/${plantDate.month}/${plantDate.year}'
            : tree.dateTime;

        markers.add(
          Marker(
            markerId: MarkerId(tree.treeId),
            position: LatLng(tree.latitude, tree.longitude),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: tree.plantName,
              snippet: 'Planted on $dateStr',
              onTap: () => widget.onTreeTap(tree.treeId),
            ),
          ),
        );
      } else if (item is ClusterItem) {
        // Generate marker for cluster
        final clusterColor = ClusteringService.getClusterColor(item.trees);
        final clusterSize = 60.0 + (item.trees.length * 2.0).clamp(0, 20);

        final markerIcon = await MarkerGenerator.createClusterMarker(
          color: clusterColor,
          count: item.trees.length,
          size: clusterSize,
        );

        markers.add(
          Marker(
            markerId: MarkerId('cluster_${item.center.latitude}_${item.center.longitude}'),
            position: LatLng(item.center.latitude, item.center.longitude),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: '${item.trees.length} trees',
              snippet: 'Zoom in to see details',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _healthCounts = counts;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    final newZoom = position.zoom;
    if ((newZoom - _currentZoom).abs() > 1.0) {
      setState(() => _currentZoom = newZoom);
      _updateMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final validTrees = widget.trees.where((t) =>
      t.latitude >= -90 && t.latitude <= 90 &&
      t.longitude >= -180 && t.longitude <= 180
    ).toList();

    final center = validTrees.isNotEmpty
        ? LatLng(validTrees.first.latitude, validTrees.first.longitude)
        : const LatLng(20.5937, 78.9629); // India center

    return Stack(
      children: [
        // Wrap GoogleMap with RawGestureDetector to handle gesture conflicts
        RawGestureDetector(
          gestures: {
            AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<AllowMultipleGestureRecognizer>(
              () => AllowMultipleGestureRecognizer(),
              (AllowMultipleGestureRecognizer instance) {},
            ),
          },
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: _currentZoom,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
        ),
        // Legend overlay
        if (_healthCounts.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: MapLegendWidget(
              healthCounts: _healthCounts,
              initiallyExpanded: false,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
