import 'package:flutter/material.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:intl/intl.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        if (syncService.isOnline && !syncService.isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: syncService.isOnline
              ? Colors.blue.shade100
              : Colors.orange.shade100,
          child: Row(
            children: [
              Icon(
                syncService.isSyncing ? Icons.sync : Icons.cloud_off,
                size: 16,
                color: syncService.isOnline
                    ? Colors.blue.shade900
                    : Colors.orange.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  syncService.isSyncing
                      ? 'Syncing data...'
                      : 'You are offline. Changes will sync when online.',
                  style: TextStyle(
                    fontSize: 12,
                    color: syncService.isOnline
                        ? Colors.blue.shade900
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (syncService.lastSyncTime != null)
                Text(
                  'Last sync: ${_formatLastSync(syncService.lastSyncTime!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(lastSync);
    }
  }
}

class SyncButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SyncButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        return IconButton(
          icon: syncService.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  syncService.isOnline ? Icons.sync : Icons.sync_disabled,
                  color: syncService.isOnline ? Colors.white : Colors.grey,
                ),
          onPressed: syncService.isSyncing
              ? null
              : onPressed ?? () => _handleSync(context, syncService),
          tooltip: syncService.isOnline ? 'Sync data' : 'Offline - Cannot sync',
        );
      },
    );
  }

  Future<void> _handleSync(
    BuildContext context,
    SyncService syncService,
  ) async {
    if (!syncService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get user ID from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await syncService.syncFromServer(
          authProvider.user!.uid,
          role: authProvider.user!.role,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data synced successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Connectivity status card for settings/profile
class ConnectivityStatusCard extends StatelessWidget {
  const ConnectivityStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      syncService.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: syncService.isOnline
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      syncService.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  syncService.isOnline
                      ? 'Connected to server. All features available.'
                      : 'Working offline. Changes will sync when you\'re back online.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                if (syncService.lastSyncTime != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.update, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Last synced: ${DateFormat('MMM d, y HH:mm').format(syncService.lastSyncTime!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (syncService.isOnline) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: syncService.isSyncing
                        ? null
                        : () => _handleManualSync(context, syncService),
                    icon: syncService.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(
                      syncService.isSyncing ? 'Syncing...' : 'Sync Now',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleManualSync(
    BuildContext context,
    SyncService syncService,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await syncService.syncFromServer(
          authProvider.user!.uid,
          role: authProvider.user!.role,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
