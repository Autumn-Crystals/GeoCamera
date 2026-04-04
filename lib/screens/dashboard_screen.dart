import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/tree_model.dart';
import '../widgets/health_analytics_widget.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/dynamic_calendar_widget.dart';
import '../services/health_calculator.dart';
import '../models/map_models.dart';
import '../widgets/map_visualization_widget.dart';

class DashboardScreen extends StatefulWidget {
  final bool showAppBar;
  const DashboardScreen({super.key, this.showAppBar = true});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _stats = {};
  List<TreeRecord> _allTrees = [];
  List<TreeRecord> _filteredTrees = [];
  String _userName = '';
  String _userRole = 'worker';
  final _searchCtrl = TextEditingController();

  // Advanced Filters
  String _selectedTimeFilter = 'All';
  List<String> _selectedAreaFilters = [];
  List<HealthStatus> _selectedHealthFilters = [];
  List<String> _availableAreas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    final stats = await DatabaseService.getStats();
    final trees = await DatabaseService.getTrees();
    if (mounted) {
      setState(() {
        _userName = user?.name ?? '';
        _userRole = user?.role ?? 'worker';
        _stats = stats;
        _allTrees = trees.reversed.toList();
        _availableAreas = _allTrees.map((t) => t.areaName ?? '').where((a) => a.isNotEmpty).toSet().toList();
        _availableAreas.sort();
        _applyAllFilters();
      });
    }
  }

  void _applyAllFilters() {
    _filterTrees(_searchCtrl.text);
  }

  void _filterTrees(String query) {
    final q = query.toLowerCase();
    final now = DateTime.now();

    setState(() {
      _filteredTrees = _allTrees.where((t) {
        // 1. Text Query Filter
        bool matchesQuery = true;
        if (q.isNotEmpty) {
          final d = DateTime.tryParse(t.dateTime);
          final monthName = d != null ? DateFormat('MMMM').format(d).toLowerCase() : '';
          matchesQuery = t.plantName.toLowerCase().contains(q) ||
              t.treeId.toLowerCase().contains(q) ||
              t.donorName.toLowerCase().contains(q) ||
              (t.areaName?.toLowerCase().contains(q) ?? false) ||
              monthName.contains(q);
        }

        if (!matchesQuery) return false;

        // 2. Time Filter
        if (_selectedTimeFilter != 'All') {
          final treeDate = DateTime.tryParse(t.dateTime);
          if (treeDate == null) return false;

          if (_selectedTimeFilter == 'Today') {
            if (treeDate.year != now.year || treeDate.month != now.month || treeDate.day != now.day) return false;
          } else if (_selectedTimeFilter == 'This Month') {
            if (treeDate.year != now.year || treeDate.month != now.month) return false;
          }
        }

        // 3. Area Filter
        if (_selectedAreaFilters.isNotEmpty) {
          if (!_selectedAreaFilters.contains(t.areaName)) return false;
        }

        // 4. Health Filter
        if (_selectedHealthFilters.isNotEmpty) {
          final health = HealthCalculator.calculateHealth(t);
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
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        title: const Text('Nisargavaidya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/gallery');
            },
          ),
          IconButton(
            icon: const Icon(Icons.people, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/donor-portal');
            },
          ),
          IconButton(icon: const Icon(Icons.logout_rounded, size: 22), onPressed: () async {
            await AuthService.logoutUser();
            if (mounted) Navigator.of(context).pushReplacementNamed('/login');
          }),
        ],
      ) : null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (b) => AppTheme.gradientPrimary.createShader(b),
                child: Text('$_userName 👋', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
              ),
              if (_userRole == 'admin')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Admin', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                controller: _searchCtrl,
                onChanged: _filterTrees,
                decoration: InputDecoration(
                  hintText: 'Search by tree, area, month...',
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
              const SizedBox(height: 12),

              // Active Filter Badges
              if (_selectedTimeFilter != 'All' || _selectedAreaFilters.isNotEmpty || _selectedHealthFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
              const SizedBox(height: 8),

              // Action buttons
              Row(children: [
                Expanded(child: _actionButton('Update Tree', Icons.refresh_rounded, () => Navigator.pushNamed(context, '/update-entry').then((_) => _loadData()), false)),
              ]),
              const SizedBox(height: 24),

              // Stats
              Row(children: [
                Expanded(child: _statCard('🌳', _stats['totalTrees'] ?? 0, 'Trees Planted', AppTheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('📸', _stats['totalUpdates'] ?? 0, 'Updates', AppTheme.info)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statCardWithCalendar(_stats['todayEntries'] ?? 0, 'Today', AppTheme.danger)),
              ]),
              const SizedBox(height: 24),

              // Sync Status
              const SyncStatusWidget(),
              const SizedBox(height: 16),

              // Weather Widget
              const WeatherWidget(),
              const SizedBox(height: 16),

              // Health Analytics
              HealthAnalyticsWidget(
                trees: _filteredTrees,
                onFilterTap: (status) {
                  if (status != null) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      if (_selectedHealthFilters.contains(status)) {
                        _selectedHealthFilters.remove(status);
                      } else {
                        _selectedHealthFilters.add(status);
                      }
                    });
                    _applyAllFilters();
                    
                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _selectedHealthFilters.contains(status)
                              ? 'Filtered by ${_statusLabel(status)}'
                              : 'Filter removed',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Map
              _sectionHeader('Plantation Map', '${_filteredTrees.length} trees'),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
                  clipBehavior: Clip.antiAlias,
                  child: MapVisualizationWidget(
                    trees: _filteredTrees,
                    onTreeTap: (treeId) {
                      Navigator.pushNamed(context, '/tree/$treeId').then((_) => _loadData());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent trees
              _sectionHeader('Recent Plantations', ''),
              const SizedBox(height: 8),
              if (_filteredTrees.isEmpty)
                _emptyState()
              else
                ..._filteredTrees.take(10).map((t) => _treeCard(t)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap, bool isPrimary) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.gradientPrimary : null,
          color: isPrimary ? null : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: AppTheme.border),
          boxShadow: isPrimary ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 16)] : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: isPrimary ? Colors.white : AppTheme.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isPrimary ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, int value, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == 'Trees Planted') {
          Navigator.pushNamed(context, '/trees-list');
        } else if (label == 'Updates') {
          Navigator.pushNamed(context, '/updates-list');
        } else if (label == 'Today') {
          Navigator.pushNamed(context, '/calendar-view');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statCardWithCalendar(int value, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/calendar-view');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          const MinimalCalendarWidget(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, String badge) {
    return Row(children: [
      const Icon(Icons.location_on, color: AppTheme.primary, size: 18),
      const SizedBox(width: 6),
      Flexible(child: Text(title, style: Theme.of(context).textTheme.headlineMedium, overflow: TextOverflow.ellipsis)),
      if (badge.isNotEmpty) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.primarySubtle, borderRadius: BorderRadius.circular(20)),
          child: Text(badge, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ]);
  }

  Future<void> _deleteTree(TreeRecord tree) async {
    if (_userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin privileges required to delete.')));
      return;
    }
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Plantation'),
      content: Text('Are you sure you want to delete "${tree.plantName}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
      ],
    ));
    if (confirm == true) {
      await DatabaseService.deleteTree(tree.treeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${tree.plantName}" deleted')));
        _loadData();
      }
    }
  }

  Widget _treeCard(TreeRecord tree) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tree/${tree.treeId}').then((_) => _loadData()),
      onLongPress: () => _deleteTree(tree),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: tree.imagePath.isNotEmpty
                ? Image.file(File(tree.imagePath), width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: AppTheme.bgElevated, child: const Icon(Icons.park, color: AppTheme.primary)))
                : Container(width: 90, height: 90, color: AppTheme.bgElevated, child: const Icon(Icons.park, color: AppTheme.primary)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: _badge(tree.treeId, AppTheme.primarySubtle, AppTheme.primary)),
                  const SizedBox(width: 6),
                  Flexible(child: _badge('${tree.updates.length} updates', const Color(0x26FBBF24), AppTheme.accent)),
                ]),
                const SizedBox(height: 6),
                Text(tree.plantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis),
                if (tree.areaName != null && tree.areaName!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(tree.areaName!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 2),
                Text('📅 ${_formatDate(tree.dateTime)}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          if (_userRole == 'admin') 
            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20), onPressed: () => _deleteTree(tree))
          else
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20)),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
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
                    Text('Filters', style: Theme.of(context).textTheme.headlineMedium),
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
                const Text('Health Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    child: const Text('Show Results', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppTheme.primarySubtle, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.park_rounded, color: AppTheme.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text('No Trees Yet', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Start by adding your first plantation!', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year}';
  }
}
