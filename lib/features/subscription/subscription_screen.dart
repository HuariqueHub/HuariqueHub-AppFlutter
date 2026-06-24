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
  bool _loadingReceipt = false;

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
    final confirmed = plan.price == 0
        ? await _confirmFreePlan(plan)
        : await _showPaymentDialog(plan);
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

  Future<bool?> _confirmFreePlan(Plan plan) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar suscripción'),
          content: Text('¿Cambiar al plan ${plan.name} (gratis)?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: kTextSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar',
                    style: TextStyle(
                        color: kOrangePrimary, fontWeight: FontWeight.bold))),
          ],
        ),
      );

  /// Formulario de pago simulado con tarjeta (US24).
  Future<bool?> _showPaymentDialog(Plan plan) {
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final digits = numberCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
          final valid = digits.length == 16 &&
              RegExp(r'^\d{2}/\d{2}$').hasMatch(expiryCtrl.text) &&
              cvvCtrl.text.length >= 3;
          return AlertDialog(
            title: const Text('Pago de membresía'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Plan ${plan.name} — S/ ${plan.price.toStringAsFixed(0)}/mes',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocal(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Número de tarjeta',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryCtrl,
                        onChanged: (_) => setLocal(() {}),
                        decoration: const InputDecoration(
                            labelText: 'MM/AA', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setLocal(() {}),
                        decoration: const InputDecoration(
                            labelText: 'CVV', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Pago simulado para fines de demostración.',
                    style: TextStyle(color: kTextSecondary, fontSize: 11)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: kTextSecondary))),
              ElevatedButton(
                onPressed: valid ? () => Navigator.pop(dialogCtx, true) : null,
                child: Text('Pagar S/ ${plan.price.toStringAsFixed(0)}'),
              ),
            ],
          );
        },
      ),
    );
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

  /// Descarga y muestra el comprobante de la suscripción activa (US25).
  Future<void> _showReceipt() async {
    if (_activeSub == null) return;
    setState(() => _loadingReceipt = true);
    try {
      final r = await _service.getReceipt(_activeSub!.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Comprobante de pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _receiptRow('N° comprobante', '${r['receiptNumber'] ?? ''}'),
              _receiptRow('Plan', '${r['planName'] ?? ''}'),
              _receiptRow('Monto',
                  '${r['currency'] ?? 'PEN'} ${(r['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _receiptRow('Estado', '${r['status'] ?? ''}'),
              _receiptRow('Emitido',
                  (r['issuedAt'] as String?)?.split('T').first ?? ''),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el comprobante')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingReceipt = false);
    }
  }

  Widget _receiptRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: kBrownDark, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

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
                            color: kOrangePrimary.withValues(alpha: 0.2),
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

                // Descargar comprobante de pago (US25)
                if (_activeSub != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: _loadingReceipt ? null : _showReceipt,
                      icon: const Icon(Icons.receipt_long, color: kOrangePrimary),
                      label: Text(
                        _loadingReceipt
                            ? 'Generando comprobante...'
                            : 'Descargar comprobante',
                        style: const TextStyle(
                            color: kOrangePrimary, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kOrangePrimary),
                        minimumSize: const Size.fromHeight(46),
                      ),
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
                      color: kOrangePrimary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
