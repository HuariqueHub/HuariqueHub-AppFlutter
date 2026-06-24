import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/preference_service.dart';
import '../../providers/auth_provider.dart';

/// Preferencias del usuario (US17) y configuración de notificaciones (US11).
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _service = PreferenceService();
  final _categoryCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  bool _notifications = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _budgetCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  int? get _userId => context.read<AuthProvider>().user?.id;

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final p = await _service.getPreferences(userId);
      _categoryCtrl.text = p['preferredCategory'] as String? ?? '';
      final budget = p['maxBudget'];
      _budgetCtrl.text = budget == null
          ? ''
          : (budget is num && budget % 1 == 0
              ? budget.toInt().toString()
              : budget.toString());
      _districtCtrl.text = p['preferredDistrict'] as String? ?? '';
      _notifications = p['notificationsEnabled'] as bool? ?? true;
    } catch (_) {
      // valores por defecto
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() { _saving = true; _error = null; _saved = false; });
    try {
      await _service.savePreferences(
        userId,
        preferredCategory: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        maxBudget: double.tryParse(_budgetCtrl.text.trim()),
        preferredDistrict: _districtCtrl.text.trim().isEmpty
            ? null
            : _districtCtrl.text.trim(),
        notificationsEnabled: _notifications,
      );
      setState(() => _saved = true);
    } catch (_) {
      setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
    } finally {
      setState(() => _saving = false);
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
        title: const Text('Mis preferencias',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kOrangePrimary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Personaliza tus recomendaciones (US17) y decide si quieres recibir notificaciones (US11).',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de comida preferida',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Presupuesto máximo (S/)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Distrito preferido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Recibir avisos de la app'),
                  value: _notifications,
                  onChanged: (v) => setState(() { _notifications = v; _saved = false; }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                if (_saved) ...[
                  const SizedBox(height: 8),
                  const Text('✓ Preferencias guardadas',
                      style: TextStyle(color: kBrownDark)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar preferencias'),
                ),
              ],
            ),
    );
  }
}
