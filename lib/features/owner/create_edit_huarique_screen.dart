import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/huarique_service.dart';
import '../../providers/auth_provider.dart';

// Mapa de respaldo nombre → id (coincide con las categorías sembradas en el
// backend) por si la carga desde el API falla. El backend exige `categoryId`.
const Map<String, int> _fallbackCategories = {
  'Pollo': 1,
  'Marina': 2,
  'Criolla': 3,
  'Chifa': 4,
  'Postres': 5,
  'Menú': 6,
  'Café': 7,
  'Parrillas': 8,
};

class CreateEditHuariqueScreen extends StatefulWidget {
  final int? huariqueId;
  const CreateEditHuariqueScreen({super.key, this.huariqueId});

  @override
  State<CreateEditHuariqueScreen> createState() =>
      _CreateEditHuariqueScreenState();
}

class _CreateEditHuariqueScreenState
    extends State<CreateEditHuariqueScreen> {
  final _service = HuariqueService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Categorías reales (nombre → id). Se inicializa con el respaldo y se
  // reemplaza con las categorías cargadas desde el backend.
  Map<String, int> _categoryIds = Map.of(_fallbackCategories);
  String _category = 'Criolla';

  bool _loading = false;
  bool _loadingExisting = false;
  String? _error;

  bool get _isEditing => widget.huariqueId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _service.getCategories();
      if (cats.isNotEmpty && mounted) {
        setState(() {
          _categoryIds = cats;
          if (!_categoryIds.containsKey(_category)) {
            _category = _categoryIds.keys.first;
          }
        });
      }
    } catch (_) {
      // Se mantiene el mapa de respaldo si falla la carga.
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final h = await _service.getById(widget.huariqueId!);
      _nameCtrl.text = h.name;
      _districtCtrl.text = h.district;
      _addressCtrl.text = h.address ?? '';
      _priceCtrl.text = h.price > 0 ? h.price.toStringAsFixed(0) : '';
      _descCtrl.text = h.description ?? '';
      setState(() {
        // Si la categoría del huarique no está en la lista, la agregamos para
        // que el dropdown pueda mostrarla sin romper.
        if (h.category.isNotEmpty && !_categoryIds.containsKey(h.category)) {
          _categoryIds = {..._categoryIds, h.category: 0};
        }
        _category = h.category.isNotEmpty ? h.category : _category;
      });
    } catch (_) {
      setState(() => _error = 'Error al cargar el huarique.');
    } finally {
      setState(() => _loadingExisting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() { _loading = true; _error = null; });
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'categoryId': _categoryIds[_category] ?? _fallbackCategories[_category] ?? 0,
        'district': _districtCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'description': _descCtrl.text.trim(),
        'ownerId': auth.user!.id,
      };
      if (_isEditing) {
        await _service.update(widget.huariqueId!, data);
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
          _isEditing ? 'Editar local' : 'Nuevo local',
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
                    _SectionLabel('Información básica'),
                    const SizedBox(height: 8),
                    // Name
                    _FormField(
                      label: 'Nombre del local *',
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ej. La Cevichería de Don Pepe'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Campo requerido' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category
                    _FormField(
                      label: 'Categoría *',
                      child: DropdownButtonFormField<String>(
                        value: _categoryIds.containsKey(_category)
                            ? _category
                            : _categoryIds.keys.first,
                        items: _categoryIds.keys
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                        decoration: const InputDecoration(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // District
                    _FormField(
                      label: 'Distrito *',
                      child: TextFormField(
                        controller: _districtCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ej. Miraflores'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Campo requerido' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Address
                    _FormField(
                      label: 'Dirección',
                      child: TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Ej. Jr. Lima 123'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Price
                    _FormField(
                      label: 'Precio promedio por persona',
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ej. 15',
                          prefixText: 'S/ ',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Description
                    _FormField(
                      label: 'Descripción',
                      child: TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Cuenta algo especial de tu local...',
                        ),
                      ),
                    ),
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
                              : 'Publicar local'),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kTextTertiary,
            letterSpacing: 0.8,
          ),
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
