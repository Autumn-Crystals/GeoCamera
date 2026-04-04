import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/tree_model.dart';

class UpdatesListScreen extends StatefulWidget {
  const UpdatesListScreen({super.key});

  @override
  State<UpdatesListScreen> createState() => _UpdatesListScreenState();
}

class _UpdatesListScreenState extends State<UpdatesListScreen> {
  List<Map<String, dynamic>> _updates = [];
  bool _isLoading = true;
  String _filterBy = 'All';
  String _timeFilter = 'All'; // All, Today, This Month
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();
    
    // Flatten all updates with tree info
    final allUpdates = <Map<String, dynamic>>[];
    for (var tree in trees) {
      for (var update in tree.updates) {
        allUpdates.add({
          'update': update,
          'tree': tree,
        });
      }
    }

    // Sort by date (most recent first)
    allUpdates.sort((a, b) => 
      (b['update'] as TreeUpdate).dateTime.compareTo((a['update'] as TreeUpdate).dateTime)
    );

    if (mounted) {
      setState(() {
        _updates = allUpdates;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUpdates {
    final q = _searchCtrl.text.toLowerCase();
    final now = DateTime.now();

    return _updates.where((item) {
      final update = item['update'] as TreeUpdate;
      final tree = item['tree'] as TreeRecord;

      // Condition filter
      if (_filterBy != 'All' && update.condition != _filterBy) return false;

      // Time filter
      if (_timeFilter != 'All') {
        final d = DateTime.tryParse(update.dateTime);
        if (d == null) return false;
        if (_timeFilter == 'Today') {
          if (d.year != now.year || d.month != now.month || d.day != now.day) return false;
        } else if (_timeFilter == 'This Month') {
          if (d.year != now.year || d.month != now.month) return false;
        }
      }

      // Text search
      if (q.isNotEmpty) {
        final matches = tree.plantName.toLowerCase().contains(q) ||
            tree.treeId.toLowerCase().contains(q) ||
            update.updatedBy.toLowerCase().contains(q) ||
            update.remarks.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Updates'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by tree, worker, remarks...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
              ),
            ),
          ),

          // Time filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: ['All', 'Today', 'This Month'].map((t) {
                final isSelected = _timeFilter == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _timeFilter = t),
                    selectedColor: AppTheme.info,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', _updates.length),
                  const SizedBox(width: 8),
                  _filterChip('Excellent', _updates.where((u) => (u['update'] as TreeUpdate).condition == 'Excellent').length),
                  const SizedBox(width: 8),
                  _filterChip('Good', _updates.where((u) => (u['update'] as TreeUpdate).condition == 'Good').length),
                  const SizedBox(width: 8),
                  _filterChip('Fair', _updates.where((u) => (u['update'] as TreeUpdate).condition == 'Fair').length),
                  const SizedBox(width: 8),
                  _filterChip('Poor', _updates.where((u) => (u['update'] as TreeUpdate).condition == 'Poor').length),
                ],
              ),
            ),
          ),

          // Updates list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredUpdates.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUpdates,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUpdates.length,
                          itemBuilder: (context, index) {
                            final item = _filteredUpdates[index];
                            return _updateCard(
                              item['update'] as TreeUpdate,
                              item['tree'] as TreeRecord,
                            );
                          },
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
      },
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _updateCard(TreeUpdate update, TreeRecord tree) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/tree/${tree.treeId}');
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
            // Update image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: update.imagePath.isNotEmpty
                  ? Image.file(
                      File(update.imagePath),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),

            // Update info
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
                        _conditionBadge(update.condition),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          update.height,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            update.updatedBy,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 ${_formatDate(update.dateTime)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (update.remarks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        update.remarks,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
      child: const Icon(Icons.photo, color: AppTheme.primary, size: 40),
    );
  }

  Widget _conditionBadge(String condition) {
    Color color;
    switch (condition) {
      case 'Excellent':
        color = AppTheme.success;
        break;
      case 'Good':
        color = const Color(0xFF10B981);
        break;
      case 'Fair':
        color = AppTheme.warning;
        break;
      case 'Poor':
        color = AppTheme.danger;
        break;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        condition,
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
            child: const Icon(Icons.update, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'No updates found',
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
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}
