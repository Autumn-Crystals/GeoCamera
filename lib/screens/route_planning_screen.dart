import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/health_calculator.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import '../models/map_models.dart';

class RoutePlanningScreen extends StatefulWidget {
  final bool showAppBar;
  const RoutePlanningScreen({super.key, this.showAppBar = true});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  List<TreeRecord> _allTrees = [];
  List<TreeRecord> _selectedTrees = [];
  String _filterMode = 'all'; // critical, needsAttention, all
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();

    // Filter by health status
    final filtered = trees.where((tree) {
      final health = HealthCalculator.calculateHealth(tree);
      if (_filterMode == 'critical') {
        return health.status == HealthStatus.critical;
      } else if (_filterMode == 'needsAttention') {
        return health.status == HealthStatus.needsAttention;
      }
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _allTrees = filtered;
        _isLoading = false;
      });
      _updateMap();
    }
  }

  void _updateMap() {
    final markers = <Marker>{};
    for (var tree in _allTrees) {
      final health = HealthCalculator.calculateHealth(tree);
      final isSelected = _selectedTrees.contains(tree);

      markers.add(Marker(
        markerId: MarkerId(tree.treeId),
        position: LatLng(tree.latitude, tree.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueBlue
              : health.status == HealthStatus.critical
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: tree.plantName,
          snippet: health.reason,
        ),
        onTap: () => _toggleTreeSelection(tree),
      ));
    }

    setState(() {
      _markers = markers;
      if (_selectedTrees.length >= 2) {
        _generateRoute();
      } else {
        _polylines = {};
      }
    });
  }

  void _toggleTreeSelection(TreeRecord tree) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTrees.contains(tree)) {
        _selectedTrees.remove(tree);
      } else {
        _selectedTrees.add(tree);
      }
    });
    _updateMap();
  }

  void _generateRoute() {
    if (_selectedTrees.length < 2) return;

    // Simple nearest neighbor route optimization
    final optimized = _optimizeRoute(_selectedTrees);
    final points = optimized.map((t) => LatLng(t.latitude, t.longitude)).toList();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppTheme.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  List<TreeRecord> _optimizeRoute(List<TreeRecord> trees) {
    if (trees.length <= 2) return trees;

    // Nearest neighbor algorithm
    final optimized = <TreeRecord>[];
    final remaining = List<TreeRecord>.from(trees);

    // Start with first tree
    optimized.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      final current = optimized.last;
      var nearestIndex = 0;
      var nearestDistance = double.infinity;

      for (var i = 0; i < remaining.length; i++) {
        final distance = _calculateDistance(
          current.latitude,
          current.longitude,
          remaining[i].latitude,
          remaining[i].longitude,
        );
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = i;
        }
      }

      optimized.add(remaining.removeAt(nearestIndex));
    }

    return optimized;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  double _calculateTotalDistance() {
    if (_selectedTrees.length < 2) return 0;
    final optimized = _optimizeRoute(_selectedTrees);
    double total = 0;
    for (var i = 0; i < optimized.length - 1; i++) {
      total += _calculateDistance(
        optimized[i].latitude,
        optimized[i].longitude,
        optimized[i + 1].latitude,
        optimized[i + 1].longitude,
      );
    }
    return total;
  }

  Future<void> _openInGoogleMaps() async {
    if (_selectedTrees.isEmpty) return;

    HapticFeedback.mediumImpact();

    final optimized = _optimizeRoute(_selectedTrees);
    final waypoints = optimized
        .skip(1)
        .take(optimized.length - 2)
        .map((t) => '${t.latitude},${t.longitude}')
        .join('|');

    final origin = '${optimized.first.latitude},${optimized.first.longitude}';
    final destination = '${optimized.last.latitude},${optimized.last.longitude}';

    final url = waypoints.isNotEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving'
        : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Route Planning'),
        actions: [
          if (_selectedTrees.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedTrees.clear());
                _updateMap();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
            ),
        ],
      ) : null,
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _filterChip('Critical', 'critical'),
                const SizedBox(width: 8),
                _filterChip('Needs Attention', 'needsAttention'),
                const SizedBox(width: 8),
                _filterChip('All', 'all'),
              ],
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _allTrees.isNotEmpty
                          ? LatLng(_allTrees.first.latitude, _allTrees.first.longitude)
                          : const LatLng(0, 0),
                      zoom: 12,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
          ),

          // Bottom info panel
          if (_selectedTrees.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          '${_selectedTrees.length}',
                          'Trees Selected',
                          Icons.park,
                          AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                          '${_calculateTotalDistance().toStringAsFixed(1)} km',
                          'Total Distance',
                          Icons.route,
                          AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.navigation, size: 20),
                        label: const Text('Start Navigation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String mode) {
    final isActive = _filterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _filterMode = mode);
          _loadTrees();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
