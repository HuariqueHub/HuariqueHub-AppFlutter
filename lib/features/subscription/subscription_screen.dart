import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/plan.dart';
import '../../data/models/subscription.dart';
import '../../data/services/subscription_service.dart';
import '../../providers/auth_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = SubscriptionService();

  List<Plan> _plans = [];
  Subscription? _activeSub;
  bool _loading = true;
  String? _selectedPlanId;
  bool _subscribing = false;

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
      final results = await Future.wait([
        _service.getPlans(),
        _service.getActiveSubscription(auth.user!.id),
      ]);
      _plans = results[0] as List<Plan>;
      _activeSub = results[1] as Subscription?;
      _selectedPlanId = _activeSub?.planId ?? (_plans.isNotEmpty ? _plans[0].id : null);
    } catch (_) {
      _plans = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(Plan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar suscripción'),
        content: Text(
          plan.price == 0
              ? '¿Cambiar al plan ${plan.name} (gratis)?'
              : '¿Suscribirte al plan ${plan.name} por S/ ${plan.price.toStringAsFixed(0)}/mes?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: kTextSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar',
                  style: TextStyle(
                      color: kOrangePrimary,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true) return;

    final auth = context.read<AuthProvider>();
    setState(() => _subscribing = true);
    try {
      await _service.subscribe(auth.user!.id, plan.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al suscribirse')),
        );
      }
    } finally {
      setState(() => _subscribing = false);
    }
  }

  Future<void> _cancel() async {
    if (_activeSub == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: const Text(
            '¿Seguro que quieres cancelar tu suscripción actual?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No',
                  style: TextStyle(color: kTextSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar',
                  style: TextStyle(color: kErrorRed))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.cancel(_activeSub!.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cancelar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSamePlan = _activeSub?.planId == _selectedPlanId;
    final target = _plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => const Plan(id: '', name: '', price: 0, features: []),
    );

    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Suscripción',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(
              _activeSub != null
                  ? 'Plan ${_activeSub!.planName ?? _activeSub!.planId} activo'
                  : 'Sin plan activo',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kOrangePrimary))
          : ListView(
              children: [
                // Active plan banner
                if (_activeSub != null)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kBrownDark, kBrownMedium],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PLAN ACTUAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _activeSub!.planName ??
                                    _activeSub!.planId,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_activeSub!.planPrice != null)
                                Text(
                                  _activeSub!.planPrice == 0
                                      ? 'Gratis'
                                      : 'S/ ${_activeSub!.planPrice!.toStringAsFixed(0)} / mes',
                                  style: const TextStyle(
                                      color: kOrangeDark, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: kOrangePrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Activo',
                            style: TextStyle(
                                color: kOrangeDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _activeSub != null ? 'Cambiar de plan' : 'Elige tu plan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kBrownDark,
                    ),
                  ),
                ),

                // Plan cards
                ..._plans.map((plan) => _PlanCard(
                      plan: plan,
                      isCurrentPlan: _activeSub?.planId == plan.id,
                      isSelected: _selectedPlanId == plan.id,
                      onSelect: () =>
                          setState(() => _selectedPlanId = plan.id),
                    )),

                const SizedBox(height: 8),

                // CTA button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: (isSamePlan || _subscribing || target.id.isEmpty)
                        ? null
                        : () => _subscribe(target),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSamePlan ? kDividerWarm : kOrangePrimary,
                      foregroundColor:
                          isSamePlan ? kTextSecondary : Colors.white,
                    ),
                    child: _subscribing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            isSamePlan
                                ? 'Este es tu plan actual'
                                : target.price == 0
                                    ? 'Suscribirme gratis'
                                    : 'Suscribirme — S/ ${target.price.toStringAsFixed(0)}/mes',
                          ),
                  ),
                ),

                // Cancel link
                if (_activeSub != null && _activeSub!.planId != 'basic') ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text(
                      'Cancelar suscripción',
                      style: TextStyle(color: kErrorRed, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrentPlan;
  final bool isSelected;
  final VoidCallback onSelect;
  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrentPlan
        ? kOrangePrimary
        : isSelected
            ? kBrownMedium
            : kDividerWarm;
    final isPopular = plan.id == 'premium';

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kOrangeLight : kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: (isSelected || isCurrentPlan) ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: kOrangePrimary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: kBrownDark,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kOrangePrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Popular',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (isCurrentPlan) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kBrownDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Actual',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  plan.price == 0
                      ? 'Gratis'
                      : 'S/ ${plan.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected ? kOrangePrimary : kBrownDark,
                  ),
                ),
              ],
            ),
            if (plan.price > 0)
              const Text('por mes',
                  style: TextStyle(fontSize: 11, color: kTextTertiary)),
            const SizedBox(height: 10),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check,
                        size: 14, color: kOrangePrimary),
                    const SizedBox(width: 8),
                    Text(f,
                        style: const TextStyle(
                            fontSize: 13, color: kTextSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
