import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/tree_model.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, Map<String, int>> _activityData = {}; // {date: {trees: count, updates: count}}
  bool _isLoading = true;
  String _viewMode = 'Both'; // Both, Trees, Updates

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();
    
    final data = <String, Map<String, int>>{};

    // Count trees planted per day
    for (var tree in trees) {
      final date = DateTime.tryParse(tree.dateTime);
      if (date != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        data[dateKey] = data[dateKey] ?? {'trees': 0, 'updates': 0};
        data[dateKey]!['trees'] = (data[dateKey]!['trees'] ?? 0) + 1;
      }
    }

    // Count updates per day
    for (var tree in trees) {
      for (var update in tree.updates) {
        final date = DateTime.tryParse(update.dateTime);
        if (date != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          data[dateKey] = data[dateKey] ?? {'trees': 0, 'updates': 0};
          data[dateKey]!['updates'] = (data[dateKey]!['updates'] ?? 0) + 1;
        }
      }
    }

    if (mounted) {
      setState(() {
        _activityData = data;
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  int _getActivityCount(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dayData = _activityData[dateKey];
    if (dayData == null) return 0;

    switch (_viewMode) {
      case 'Trees':
        return dayData['trees'] ?? 0;
      case 'Updates':
        return dayData['updates'] ?? 0;
      default: // Both
        return (dayData['trees'] ?? 0) + (dayData['updates'] ?? 0);
    }
  }

  Color _getHeatmapColor(int count) {
    if (count == 0) return AppTheme.bgElevated;
    if (count <= 2) return AppTheme.primary.withOpacity(0.3);
    if (count <= 5) return AppTheme.primary.withOpacity(0.5);
    if (count <= 10) return AppTheme.primary.withOpacity(0.7);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Calendar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              HapticFeedback.lightImpact();
              setState(() => _viewMode = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Both', child: Text('Show Both')),
              const PopupMenuItem(value: 'Trees', child: Text('Trees Only')),
              const PopupMenuItem(value: 'Updates', child: Text('Updates Only')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month selector
                  _buildMonthSelector(),
                  const SizedBox(height: 24),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 16),

                  // Calendar grid
                  _buildCalendar(),
                  const SizedBox(height: 24),

                  // Monthly summary
                  _buildMonthlySummary(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              HapticFeedback.lightImpact();
              _previousMonth();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              HapticFeedback.lightImpact();
              _nextMonth();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Level',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Less', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              _legendBox(0),
              const SizedBox(width: 4),
              _legendBox(1),
              const SizedBox(width: 4),
              _legendBox(3),
              const SizedBox(width: 4),
              _legendBox(6),
              const SizedBox(width: 4),
              _legendBox(11),
              const SizedBox(width: 8),
              const Text('More', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendBox(int count) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getHeatmapColor(count),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar days
          ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 40, height: 40);
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final count = _getActivityCount(date);
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);
                  final dayData = _activityData[dateKey];

                  return GestureDetector(
                    onTap: count > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            _showDayDetails(date, dayData);
                          }
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(count),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: date.day == DateTime.now().day &&
                                  date.month == DateTime.now().month &&
                                  date.year == DateTime.now().year
                              ? AppTheme.primary
                              : AppTheme.border.withOpacity(0.3),
                          width: date.day == DateTime.now().day &&
                                  date.month == DateTime.now().month &&
                                  date.year == DateTime.now().year
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: count > 5
                                ? Colors.white
                                : count > 0
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
    int totalTrees = 0;
    int totalUpdates = 0;
    int activeDays = 0;

    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    for (var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      final dateKey = DateFormat('yyyy-MM-dd').format(day);
      final dayData = _activityData[dateKey];
      if (dayData != null) {
        totalTrees += dayData['trees'] ?? 0;
        totalUpdates += dayData['updates'] ?? 0;
        if ((dayData['trees'] ?? 0) > 0 || (dayData['updates'] ?? 0) > 0) {
          activeDays++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('🌳', totalTrees, 'Trees'),
              _summaryItem('📸', totalUpdates, 'Updates'),
              _summaryItem('📅', activeDays, 'Active Days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String emoji, int count, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showDayDetails(DateTime date, Map<String, int>? data) {
    if (data == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FutureBuilder<List<TreeRecord>>(
        future: DatabaseService.getTrees(),
        builder: (context, snapshot) {
          final allTrees = snapshot.data ?? [];
          
          // Filter trees planted on this date
          final plantedTrees = allTrees.where((t) {
            final d = DateTime.tryParse(t.dateTime);
            return d != null && DateFormat('yyyy-MM-dd').format(d) == dateKey;
          }).toList();

          // Filter updates made on this date
          final updatesOnDay = <Map<String, dynamic>>[];
          for (final tree in allTrees) {
            for (final update in tree.updates) {
              final d = DateTime.tryParse(update.dateTime);
              if (d != null && DateFormat('yyyy-MM-dd').format(d) == dateKey) {
                updatesOnDay.add({'update': update, 'tree': tree});
              }
            }
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollCtrl) => SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(date),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary chips
                  Row(
                    children: [
                      _daySummaryChip('🌳 ${plantedTrees.length} Planted', AppTheme.success),
                      const SizedBox(width: 8),
                      _daySummaryChip('📸 ${updatesOnDay.length} Updates', AppTheme.info),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Trees planted section
                  if (plantedTrees.isNotEmpty) ...[
                    const Text('Trees Planted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...plantedTrees.map((tree) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/tree/${tree.treeId}');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.park, color: AppTheme.success, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tree.plantName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (tree.areaName != null && tree.areaName!.isNotEmpty)
                                    Text(tree.areaName!, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Updates section
                  if (updatesOnDay.isNotEmpty) ...[
                    const Text('Updates Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...updatesOnDay.map((item) {
                      final tree = item['tree'] as TreeRecord;
                      final update = item['update'] as TreeUpdate;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/tree/${tree.treeId}');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.update, color: AppTheme.info, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tree.plantName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text('By ${update.updatedBy} · ${update.condition}',
                                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _daySummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detailCard(String emoji, int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
