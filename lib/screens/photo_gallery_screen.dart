import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/health_calculator.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final bool showAppBar;
  const PhotoGalleryScreen({super.key, this.showAppBar = true});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<TreeRecord> _trees = [];
  List<_PhotoItem> _allPhotos = [];
  List<_PhotoItem> _filteredPhotos = [];
  String _filterMode = 'all'; // all, initial, updates
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  // Advanced Filters
  String _selectedTimeFilter = 'All';
  List<String> _selectedAreaFilters = [];
  List<HealthStatus> _selectedHealthFilters = [];
  List<String> _availableAreas = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();
    final photos = <_PhotoItem>[];

    for (var tree in trees) {
      // Add initial photo
      if (tree.imagePath.isNotEmpty) {
        photos.add(_PhotoItem(
          imagePath: tree.imagePath,
          tree: tree,
          isInitial: true,
          date: DateTime.parse(tree.dateTime),
          label: 'Initial Planting',
        ));
      }

      // Add update photos
      for (var i = 0; i < tree.updates.length; i++) {
        final update = tree.updates[i];
        if (update.imagePath.isNotEmpty) {
          photos.add(_PhotoItem(
            imagePath: update.imagePath,
            tree: tree,
            isInitial: false,
            date: DateTime.parse(update.dateTime),
            label: 'Update #${i + 1}',
            condition: update.condition,
          ));
        }
      }
    }

    // Sort by date descending
    photos.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _trees = trees;
        _allPhotos = photos;
        _availableAreas = trees.map((t) => t.areaName ?? '').where((a) => a.isNotEmpty).toSet().toList();
        _availableAreas.sort();
        _isLoading = false;
        _applyAllFilters();
      });
    }
  }

  void _applyAllFilters() {
    _applyFilter(_filterMode);
  }

  void _applyFilter(String mode) {
    final q = _searchCtrl.text.toLowerCase();
    final now = DateTime.now();

    setState(() {
      _filterMode = mode;
      _filteredPhotos = _allPhotos.where((p) {
        // 1. Initial/Update Filter
        if (mode == 'initial' && !p.isInitial) return false;
        if (mode == 'updates' && p.isInitial) return false;

        // 2. Text Search Filter
        if (q.isNotEmpty) {
          final matches = p.tree.plantName.toLowerCase().contains(q) ||
              p.tree.treeId.toLowerCase().contains(q) ||
              (p.tree.areaName?.toLowerCase().contains(q) ?? false);
          if (!matches) return false;
        }

        // 3. Time Filter
        if (_selectedTimeFilter != 'All') {
          if (_selectedTimeFilter == 'Today') {
            if (p.date.year != now.year || p.date.month != now.month || p.date.day != now.day) return false;
          } else if (_selectedTimeFilter == 'This Month') {
            if (p.date.year != now.year || p.date.month != now.month) return false;
          }
        }

        // 4. Area Filter
        if (_selectedAreaFilters.isNotEmpty) {
          if (!_selectedAreaFilters.contains(p.tree.areaName ?? '')) return false;
        }

        // 5. Health Filter
        if (_selectedHealthFilters.isNotEmpty) {
          final health = HealthCalculator.calculateHealth(p.tree);
          if (!_selectedHealthFilters.contains(health.status)) return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedTimeFilter = 'All';
      _selectedAreaFilters = [];
      _selectedHealthFilters = [];
      _filterMode = 'all';
    });
    _applyAllFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Toggle grid size or view mode if needed
            },
          ),
        ],
      ) : null,
      body: Column(
        children: [
          // Permanent Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyAllFilters(),
              decoration: InputDecoration(
                hintText: 'Search photos...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); _applyAllFilters(); }
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.tune,
                        size: 20,
                        color: (_selectedTimeFilter != 'All' || _selectedAreaFilters.isNotEmpty || _selectedHealthFilters.isNotEmpty)
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                      onPressed: _showFilterSheet,
                    ),
                  ],
                ),
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.border)),
              ),
            ),
          ),

          // Active Filter Badges
          if (_selectedTimeFilter != 'All' || _selectedAreaFilters.isNotEmpty || _selectedHealthFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedTimeFilter != 'All')
                      _filterBadge(_selectedTimeFilter, () {
                        setState(() => _selectedTimeFilter = 'All');
                        _applyAllFilters();
                      }),
                    ..._selectedAreaFilters.map((area) => _filterBadge(area, () {
                      setState(() => _selectedAreaFilters.remove(area));
                      _applyAllFilters();
                    })),
                    ..._selectedHealthFilters.map((status) => _filterBadge(_statusLabel(status), () {
                      setState(() => _selectedHealthFilters.remove(status));
                      _applyAllFilters();
                    })),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // Quick Selection Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('All', 'all', _allPhotos.length),
                const SizedBox(width: 8),
                _filterChip('Initial', 'initial', _allPhotos.where((p) => p.isInitial).length),
                const SizedBox(width: 8),
                _filterChip('Updates', 'updates', _allPhotos.where((p) => !p.isInitial).length),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Photo grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredPhotos.isEmpty
                    ? _emptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _filteredPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = _filteredPhotos[index];
                          return _photoTile(photo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String mode, int count) {
    final isActive = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _applyFilter(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.2) : AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoTile(_PhotoItem photo) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showPhotoDetail(photo);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.bgElevated,
                child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
              ),
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.tree.plantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photo.label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (photo.condition != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _getConditionColor(photo.condition!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          photo.condition!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
        return AppTheme.success;
      case 'moderate':
        return AppTheme.warning;
      case 'poor':
        return AppTheme.danger;
      default:
        return Colors.white;
    }
  }

  void _showPhotoDetail(_PhotoItem photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailScreen(photo: photo),
      ),
    );
  }

  Widget _filterBadge(String label, VoidCallback onClear) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 16, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  String _statusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy: return 'Healthy';
      case HealthStatus.needsAttention: return 'Needs Attention';
      case HealthStatus.critical: return 'Critical';
      case HealthStatus.newPlantation: return 'New';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Full Gallery Filters', style: Theme.of(context).textTheme.headlineMedium),
                    TextButton(
                      onPressed: () {
                        _clearAllFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All', style: TextStyle(color: AppTheme.danger)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Time Filter
                const Text('Time Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Today', 'This Month'].map((time) {
                    final isSelected = _selectedTimeFilter == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setModalState(() => _selectedTimeFilter = time);
                          setState(() => _selectedTimeFilter = time);
                          _applyAllFilters();
                        }
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Health Filter
                const Text('Health Status of Tree', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: HealthStatus.values.map((status) {
                    final isSelected = _selectedHealthFilters.contains(status);
                    return FilterChip(
                      label: Text(_statusLabel(status)),
                      selected: isSelected,
                      onSelected: (val) {
                        setModalState(() {
                          if (val) _selectedHealthFilters.add(status);
                          else _selectedHealthFilters.remove(status);
                        });
                        setState(() {});
                        _applyAllFilters();
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Area Filter
                if (_availableAreas.isNotEmpty) ...[
                  const Text('Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableAreas.map((area) {
                      final isSelected = _selectedAreaFilters.contains(area);
                      return FilterChip(
                        label: Text(area),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) _selectedAreaFilters.add(area);
                            else _selectedAreaFilters.remove(area);
                          });
                          setState(() {});
                          _applyAllFilters();
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('See Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primarySubtle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.photo_library, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('No Photos Yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Photos will appear here as you add trees',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PhotoItem {
  final String imagePath;
  final TreeRecord tree;
  final bool isInitial;
  final DateTime date;
  final String label;
  final String? condition;

  _PhotoItem({
    required this.imagePath,
    required this.tree,
    required this.isInitial,
    required this.date,
    required this.label,
    this.condition,
  });
}

class _PhotoDetailScreen extends StatelessWidget {
  final _PhotoItem photo;

  const _PhotoDetailScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(photo.tree.plantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/tree/${photo.tree.treeId}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.file(
                  File(photo.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: photo.isInitial ? AppTheme.primarySubtle : const Color(0x26FBBF24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        photo.label,
                        style: TextStyle(
                          color: photo.isInitial ? AppTheme.primary : AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (photo.condition != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConditionColor(photo.condition!).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          photo.condition!,
                          style: TextStyle(
                            color: _getConditionColor(photo.condition!),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  photo.tree.plantName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 ${DateFormat('dd MMM yyyy, hh:mm a').format(photo.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (photo.tree.areaName != null && photo.tree.areaName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${photo.tree.areaName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
        return AppTheme.success;
      case 'moderate':
        return AppTheme.warning;
      case 'poor':
        return AppTheme.danger;
      default:
        return AppTheme.textPrimary;
    }
  }
}
