import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/promo.dart';
import '../../data/services/promo_service.dart';
import '../../providers/auth_provider.dart';

const Map<String, String> _typeEmoji = {
  '2x1': '🍗',
  'descuento': '%',
  'menu': '🍽️',
  'happy-hour': '🍹',
  'otro': '🎉',
};

class OwnerPromosScreen extends StatefulWidget {
  const OwnerPromosScreen({super.key});

  @override
  State<OwnerPromosScreen> createState() => _OwnerPromosScreenState();
}

class _OwnerPromosScreenState extends State<OwnerPromosScreen> {
  final _service = PromoService();
  List<Promo> _promos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _promos = await _service.getAll();
    } catch (_) {
      _promos = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Promo p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar promo'),
        content: Text('¿Eliminar "${p.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: kTextSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(
                      color: kErrorRed, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.delete(p.id);
      _load();
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis Promos',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Gestiona tus promociones',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () =>
                context.push('/owner/promos/new').then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kOrangePrimary))
          : _promos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉',
                          style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      const Text('Sin promos todavía',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary)),
                      const SizedBox(height: 4),
                      const Text(
                          'Toca + para crear tu primera promoción',
                          style: TextStyle(
                              color: kTextSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .push('/owner/promos/new')
                            .then((_) => _load()),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva promo'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _promos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PromoCard(
                    promo: _promos[i],
                    onEdit: () => context
                        .push('/owner/promos/${_promos[i].id}/edit')
                        .then((_) => _load()),
                    onDelete: () => _delete(_promos[i]),
                  ),
                ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Promo promo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PromoCard({
    required this.promo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _typeEmoji[promo.type] ?? '🎉';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: kBrownDark)),
                  if (promo.note != null && promo.note!.isNotEmpty)
                    Text(promo.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: promo.isActive
                              ? kOrangePrimary.withOpacity(0.15)
                              : kDividerWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promo.isActive ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            fontSize: 10,
                            color: promo.isActive
                                ? kOrangePrimary
                                : kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (promo.discount != null && promo.discount! > 0) ...[
                        const SizedBox(width: 6),
                        Text('${promo.discount}% off',
                            style: const TextStyle(
                                fontSize: 11,
                                color: kOrangePrimary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  iconSize: 18,
                  icon: const Icon(Icons.edit, color: kBrownMedium),
                ),
                IconButton(
                  onPressed: onDelete,
                  iconSize: 18,
                  icon: const Icon(Icons.delete, color: kErrorRed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
