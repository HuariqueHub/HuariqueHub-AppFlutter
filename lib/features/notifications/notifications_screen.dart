import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_notification.dart';
import '../../data/services/notification_service.dart';
import '../../providers/auth_provider.dart';

/// Lista de notificaciones del usuario (US12). Al tocar una se marca como leída.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      _items = await _service.getNotifications(userId);
    } catch (_) {
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() {
      _items = _items
          .map((e) => e.id == n.id ? e.copyWith(isRead: true) : e)
          .toList();
    });
    try {
      await _service.markAsRead(n.id);
    } catch (_) {
      // si falla, no es bloqueante
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notificaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kOrangePrimary))
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 44)),
                      SizedBox(height: 8),
                      Text('No tienes notificaciones',
                          style: TextStyle(color: kTextSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = _items[i];
                    return Card(
                      color: n.isRead ? kSurfaceColor : kOrangeLight,
                      child: ListTile(
                        leading: const Icon(Icons.notifications,
                            color: kOrangePrimary),
                        title: Text(n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: kBrownDark)),
                        subtitle: Text(
                          '${n.body}${n.date.isNotEmpty ? '\n${n.date}' : ''}',
                          style: const TextStyle(color: kTextSecondary),
                        ),
                        isThreeLine: n.date.isNotEmpty,
                        trailing: n.isRead
                            ? null
                            : const Icon(Icons.circle,
                                size: 10, color: kOrangePrimary),
                        onTap: () => _markRead(n),
                      ),
                    );
                  },
                ),
    );
  }
}
