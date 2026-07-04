import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/permissions_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _notificationSettings = {};
  bool _isLoading = true;
  String _userRole = 'worker';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getSettings();
    final user = await AuthService.getCurrentUser();
    
    if (mounted) {
      setState(() {
        _notificationSettings = settings;
        _userRole = user?.role ?? 'worker';
        _userName = user?.name ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Section
          _buildSection(
            'Account',
            [
              _buildInfoTile(
                Icons.person,
                'Name',
                _userName,
              ),
              _buildInfoTile(
                Icons.badge,
                'Role',
                PermissionsService.getRoleDisplayName(_userRole),
                roleColor: _userRole,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                Icons.notifications_active,
                'Daily Reminders',
                'Get reminded to check your trees',
                _notificationSettings['daily_reminder_enabled'] ?? false,
                (value) async {
                  if (value) {
                    await _showTimePickerDialog();
                  } else {
                    await NotificationService.cancelDailyReminder();
                    await _loadSettings();
                  }
                },
              ),
              if (_notificationSettings['daily_reminder_enabled'] == true)
                _buildInfoTile(
                  Icons.access_time,
                  'Reminder Time',
                  '${_notificationSettings['daily_reminder_hour']}:${_notificationSettings['daily_reminder_minute'].toString().padLeft(2, '0')}',
                  onTap: _showTimePickerDialog,
                ),
              _buildSwitchTile(
                Icons.warning_amber,
                'Overdue Alerts',
                'Notify when trees need updates',
                _notificationSettings['overdue_alerts_enabled'] ?? true,
                (value) async {
                  await NotificationService.updateSettings({
                    'overdue_alerts_enabled': value,
                  });
                  await _loadSettings();
                },
              ),
              _buildSwitchTile(
                Icons.summarize,
                'Weekly Summary',
                'Get weekly plantation reports',
                _notificationSettings['weekly_summary_enabled'] ?? true,
                (value) async {
                  await NotificationService.updateSettings({
                    'weekly_summary_enabled': value,
                  });
                  await _loadSettings();
                },
              ),
              _buildActionTile(
                Icons.send,
                'Test Notification',
                'Send a test notification',
                () async {
                  HapticFeedback.lightImpact();
                  await NotificationService.showNotification(
                    id: 999,
                    title: 'Test Notification',
                    body: 'Notifications are working! 🌳',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Export Section
          FutureBuilder<bool>(
            future: PermissionsService.hasPermission(Permission.exportData),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              
              return Column(
                children: [
                  _buildSection(
                    'Data Export & Backup',
                    [
                      _buildActionTile(
                        Icons.table_chart,
                        'Export to Excel',
                        'Download all data as Excel file',
                        () async {
                          HapticFeedback.mediumImpact();
                          _showLoadingDialog('Exporting to Excel...');
                          try {
                            await ExportService.exportAndShareExcel();
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Excel file exported successfully!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Export failed: $e'),
                                  backgroundColor: AppTheme.danger,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildActionTile(
                        Icons.description,
                        'Export to CSV',
                        'Download all data as CSV file',
                        () async {
                          HapticFeedback.mediumImpact();
                          _showLoadingDialog('Exporting to CSV...');
                          try {
                            await ExportService.exportAndShareCSV();
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('CSV file exported successfully!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Export failed: $e'),
                                  backgroundColor: AppTheme.danger,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildActionTile(
                        Icons.backup,
                        'Create Backup',
                        'Full backup of all data (JSON)',
                        () async {
                          HapticFeedback.mediumImpact();
                          _showLoadingDialog('Creating backup...');
                          try {
                            await ExportService.shareBackup();
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Backup created successfully!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // Close loading
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Backup failed: $e'),
                                  backgroundColor: AppTheme.danger,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // About Section
          _buildSection(
            'About',
            [
              _buildInfoTile(
                Icons.info,
                'Version',
                '1.0.0',
              ),
              _buildInfoTile(
                Icons.business,
                'Organization',
                'NGO Tree Tracker',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          onChanged(val);
        },
        activeColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value, {
    String? roleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      trailing: roleColor != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(int.parse(PermissionsService.getRoleColor(roleColor).replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
      onTap: onTap,
    );
  }

  Future<void> _showTimePickerDialog() async {
    final currentHour = _notificationSettings['daily_reminder_hour'] ?? 9;
    final currentMinute = _notificationSettings['daily_reminder_minute'] ?? 0;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );

    if (time != null) {
      await NotificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily reminder set for ${time.format(context)}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
