import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  bool _isOnline = true;
  int _pendingCount = 0;
  DateTime? _lastSync;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final online = await SyncService.isOnline();
    final pending = await SyncService.getPendingSyncCount();
    final lastSync = await SyncService.getLastSyncTime();

    if (mounted) {
      setState(() {
        _isOnline = online;
        _pendingCount = pending;
        _lastSync = lastSync;
      });
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    HapticFeedback.mediumImpact();

    final result = await SyncService.syncPendingItems();

    if (mounted) {
      setState(() => _isSyncing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.success : AppTheme.danger,
        ),
      );

      _checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0 && _isOnline) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _isOnline && _pendingCount > 0 ? _syncNow : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isOnline ? AppTheme.info.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isOnline ? AppTheme.info.withValues(alpha: 0.3) : AppTheme.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isOnline ? AppTheme.info.withValues(alpha: 0.2) : AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.info,
                        ),
                      ),
                    )
                  : Icon(
                      _isOnline ? Icons.cloud_upload : Icons.cloud_off,
                      color: _isOnline ? AppTheme.info : AppTheme.warning,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline
                        ? (_pendingCount > 0 ? 'Pending Sync' : 'All Synced')
                        : 'Offline Mode',
                    style: TextStyle(
                      color: _isOnline ? AppTheme.info : AppTheme.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOnline
                        ? (_pendingCount > 0
                            ? '$_pendingCount items waiting to sync'
                            : _lastSync != null
                                ? 'Last synced ${_formatTime(_lastSync!)}'
                                : 'No pending items')
                        : 'Changes will sync when online',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_isOnline && _pendingCount > 0 && !_isSyncing)
              const Icon(Icons.sync, color: AppTheme.info, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
