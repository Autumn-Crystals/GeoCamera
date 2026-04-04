import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/tree_model.dart';
import '../services/health_calculator.dart';
import '../models/map_models.dart';

class TreesListScreen extends StatefulWidget {
  const TreesListScreen({super.key});

  @override
  State<TreesListScreen> createState() => _TreesListScreenState();
}

class _TreesListScreenState extends State<TreesListScreen> {
  List<TreeRecord> _trees = [];
  List<TreeRecord> _filteredTrees = [];
  bool _isLoading = true;
  String _sortBy = 'Recent';
  String _filterBy = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();
    if (mounted) {
      setState(() {
        _trees = trees;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    var filtered = List<TreeRecord>.from(_trees);

    // Text search
    if (q.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.plantName.toLowerCase().contains(q) ||
        t.treeId.toLowerCase().contains(q) ||
        t.donorName.toLowerCase().contains(q) ||
        (t.areaName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // Health filter
    if (_filterBy != 'All') {
      filtered = filtered.where((tree) {
        final health = HealthCalculator.calculateHealth(tree);
        switch (_filterBy) {
          case 'Healthy': return health.status == HealthStatus.healthy;
          case 'Needs Attention': return health.status == HealthStatus.needsAttention;
          case 'Critical': return health.status == HealthStatus.critical;
          default: return true;
        }
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Recent':
        filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'Name':
        filtered.sort((a, b) => a.plantName.compareTo(b.plantName));
        break;
      case 'Health':
        filtered.sort((a, b) {
          final healthA = HealthCalculator.calculateHealth(a);
          final healthB = HealthCalculator.calculateHealth(b);
          return (healthB.daysSinceUpdate).compareTo(healthA.daysSinceUpdate);
        });
        break;
    }

    setState(() => _filteredTrees = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trees'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Recent', child: Text('Sort by Recent')),
              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'Health', child: Text('Sort by Health')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by name, area, donor...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); _applyFilters(); })
                    : null,
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
              ),
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', _trees.length),
                  const SizedBox(width: 8),
                  _filterChip('Healthy', _trees.where((t) => HealthCalculator.calculateHealth(t).status == HealthStatus.healthy).length),
                  const SizedBox(width: 8),
                  _filterChip('Needs Attention', _trees.where((t) => HealthCalculator.calculateHealth(t).status == HealthStatus.needsAttention).length),
                  const SizedBox(width: 8),
                  _filterChip('Critical', _trees.where((t) => HealthCalculator.calculateHealth(t).status == HealthStatus.critical).length),
                ],
              ),
            ),
          ),

          // Trees list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredTrees.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTrees,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTrees.length,
                          itemBuilder: (context, index) => _treeCard(_filteredTrees[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _filterBy == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.lightImpact();
        setState(() => _filterBy = label);
        _applyFilters();
      },
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _treeCard(TreeRecord tree) {
    final health = HealthCalculator.calculateHealth(tree);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/tree/${tree.treeId}').then((_) => _loadTrees());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Tree image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: tree.imagePath.isNotEmpty
                  ? Image.file(
                      File(tree.imagePath),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),

            // Tree info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tree.plantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _healthBadge(health),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tree.treeId,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '👤 ${tree.donorName}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tree.areaName != null && tree.areaName!.isNotEmpty)
                      Text(
                        '📍 ${tree.areaName}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '📅 ${_formatDate(tree.dateTime)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '${tree.updates.length} updates',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.bgElevated,
      child: const Icon(Icons.park, color: AppTheme.primary, size: 40),
    );
  }

  Widget _healthBadge(TreeHealthStatus health) {
    Color color = AppTheme.textMuted;
    String label = 'Unknown';

    switch (health.status) {
      case HealthStatus.healthy:
        color = AppTheme.success;
        label = 'Healthy';
        break;
      case HealthStatus.needsAttention:
        color = AppTheme.warning;
        label = 'Attention';
        break;
      case HealthStatus.critical:
        color = AppTheme.danger;
        label = 'Critical';
        break;
      case HealthStatus.newPlantation:
        color = AppTheme.info;
        label = 'New';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
            child: const Icon(Icons.park, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'No trees found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return DateFormat('dd MMM yyyy').format(date);
  }
}
    