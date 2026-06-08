import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/huarique.dart';
import '../../data/services/huarique_service.dart';
import '../../providers/auth_provider.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _service = HuariqueService();
  List<Huarique> _huariques = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _loading = true);
    try {
      _huariques = await _service.getByOwner(auth.user!.id);
    } catch (_) {
      _huariques = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Huarique h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar huarique'),
        content:
            Text('¿Seguro que quieres eliminar "${h.name}"? Esta acción no se puede deshacer.'),
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
      await _service.delete(h.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kWarmWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/owner/huarique/new').then((_) => _load()),
        backgroundColor: kOrangePrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kBrownDark,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mi Panel',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('Hola, ${auth.user?.name.split(' ').first ?? ''}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
            leading: null,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => auth.logout(),
              ),
            ],
          ),

          // Stats banner
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kBrownDark, Color(0xFF5A2E12)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  _StatCard(
                    value: _huariques.length.toString(),
                    label: 'Locales',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: _huariques.isEmpty
                        ? '—'
                        : (_huariques
                                .map((h) => h.rating)
                                .reduce((a, b) => a + b) /
                            _huariques.length)
                            .toStringAsFixed(1),
                    label: 'Rating prom.',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    value: _huariques
                        .fold(0, (sum, h) => sum + h.reviewCount)
                        .toString(),
                    label: 'Reseñas',
                  ),
                ],
              ),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push('/owner/promos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kOrangePrimary,
                            side: const BorderSide(color: kOrangePrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('🎉 Mis promos',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context
                              .push('/owner/huarique/new')
                              .then((_) => _load()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBrownMedium,
                            side:
                                const BorderSide(color: kDividerWarm),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('+ Nuevo local',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/subscription'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBrownDark,
                        side: BorderSide(
                            color: kBrownMedium.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('⭐ Mi suscripción',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                'Mis locales',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kBrownDark,
                ),
              ),
            ),
          ),

          // Content
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: kOrangePrimary)),
              ),
            )
          else if (_huariques.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Text('🏪',
                        style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    const Text('Aún no tienes locales',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 4),
                    const Text(
                        'Toca el botón + para agregar tu primer huarique',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 88),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OwnerHuariqueCard(
                      huarique: _huariques[i],
                      onEdit: () => context
                          .push('/owner/huarique/${_huariques[i].id}/edit')
                          .then((_) => _load()),
                      onDelete: () => _delete(_huariques[i]),
                    ),
                  ),
                  childCount: _huariques.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _OwnerHuariqueCard extends StatelessWidget {
  final Huarique huarique;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OwnerHuariqueCard({
    required this.huarique,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('🍽️', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(huarique.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: kBrownDark)),
                  Text('${huarique.category} · ${huarique.district}',
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: kStarYellow),
                      const SizedBox(width: 2),
                      Text(huarique.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12,
                              color: kBrownDark,
                              fontWeight: FontWeight.w500)),
                      if (huarique.price > 0) ...[
                        const SizedBox(width: 10),
                        Text('S/ ${huarique.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, color: kOrangePrimary)),
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
