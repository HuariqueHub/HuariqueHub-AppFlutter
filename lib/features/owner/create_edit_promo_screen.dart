import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/promo_service.dart';

class _PromoType {
  final String key;
  final String label;
  final String emoji;
  const _PromoType(this.key, this.label, this.emoji);
}

const _promoTypes = [
  _PromoType('2x1', '2×1', '🍗'),
  _PromoType('descuento', 'Descuento %', '%'),
  _PromoType('menu', 'Menú especial', '🍽️'),
  _PromoType('happy-hour', 'Happy hour', '🍹'),
  _PromoType('otro', 'Otro', '🎉'),
];

class CreateEditPromoScreen extends StatefulWidget {
  final int? promoId;
  const CreateEditPromoScreen({super.key, this.promoId});

  @override
  State<CreateEditPromoScreen> createState() =>
      _CreateEditPromoScreenState();
}

class _CreateEditPromoScreenState extends State<CreateEditPromoScreen> {
  final _service = PromoService();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  String _typeKey = 'otro';

  bool _loading = false;
  bool _loadingExisting = false;
  String? _error;

  bool get _isEditing => widget.promoId != null;
  bool get _showDiscount =>
      _typeKey == 'descuento' || _typeKey == '2x1';

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _discountCtrl.dispose();
    _codeCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final p = await _service.getById(widget.promoId!);
      _titleCtrl.text = p.title;
      _noteCtrl.text = p.note ?? '';
      _typeKey = p.type;
      _discountCtrl.text = (p.discount ?? 0) > 0
          ? p.discount!.toString()
          : '';
      _codeCtrl.text = p.code ?? '';
      _startCtrl.text = p.startDate ?? '';
      _endCtrl.text = p.endDate ?? '';
      _maxUsesCtrl.text = p.maxUses?.toString() ?? '';
      setState(() {});
    } catch (_) {
      setState(() => _error = 'Error al cargar la promo.');
    } finally {
      setState(() => _loadingExisting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'type': _typeKey,
        'discount': int.tryParse(_discountCtrl.text) ?? 0,
        'code': _codeCtrl.text.trim(),
        'startDate': _startCtrl.text.trim().isEmpty ? null : _startCtrl.text.trim(),
        'endDate': _endCtrl.text.trim().isEmpty ? null : _endCtrl.text.trim(),
        'maxUses': int.tryParse(_maxUsesCtrl.text),
      };
      if (_isEditing) {
        await _service.update(widget.promoId!, data);
      } else {
        await _service.create(data);
      }
      if (mounted) context.pop();
    } catch (_) {
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      setState(() => _loading = false);
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
        title: Text(
          _isEditing ? 'Editar promo' : 'Nueva promo',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadingExisting
          ? const Center(
              child: CircularProgressIndicator(color: kOrangePrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Información básica ──────────────────────────────
                    _SectionLabel('Información básica'),
                    const SizedBox(height: 8),

                    _FormField(
                      label: 'Título de la promo *',
                      child: TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ej. 2×1 Pollo Hoy'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Campo requerido' : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      label: 'Tipo de promo *',
                      child: DropdownButtonFormField<String>(
                        initialValue: _typeKey,
                        items: _promoTypes
                            .map((t) => DropdownMenuItem(
                                  value: t.key,
                                  child: Text('${t.emoji}  ${t.label}'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _typeKey = v ?? _typeKey;
                            if (!_showDiscount) _discountCtrl.clear();
                          });
                        },
                        decoration: const InputDecoration(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      label: 'Descripción / nota *',
                      child: TextFormField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Solo Lun–Vie de 12:00 a 16:00',
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Campo requerido' : null,
                      ),
                    ),

                    // ── Descuento ───────────────────────────────────────
                    if (_showDiscount) ...[
                      const SizedBox(height: 20),
                      _SectionLabel('Descuento'),
                      const SizedBox(height: 8),
                      _FormField(
                        label: 'Porcentaje de descuento',
                        child: TextFormField(
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Ej. 20',
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],

                    // ── Código y límites ────────────────────────────────
                    const SizedBox(height: 20),
                    _SectionLabel('Código y límites'),
                    const SizedBox(height: 8),

                    _FormField(
                      label: 'Código de canje (opcional)',
                      child: TextFormField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ej. PROMO20'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      label: 'Máximo de usos (opcional)',
                      child: TextFormField(
                        controller: _maxUsesCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            hintText:
                                'Ej. 100 — vacío = ilimitado'),
                      ),
                    ),

                    // ── Vigencia ────────────────────────────────────────
                    const SizedBox(height: 20),
                    _SectionLabel('Vigencia'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: 'Fecha inicio',
                            child: TextFormField(
                              controller: _startCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-DD'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: 'Fecha fin',
                            child: TextFormField(
                              controller: _endCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-DD'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Error & button ──────────────────────────────────
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(_error!,
                          style: const TextStyle(
                              color: kErrorRed, fontSize: 13)),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(_isEditing
                              ? 'Guardar cambios'
                              : 'Publicar promo'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kTextTertiary,
          letterSpacing: 0.8,
        ),
      );
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary)),
          const SizedBox(height: 4),
          child,
        ],
      );
}
