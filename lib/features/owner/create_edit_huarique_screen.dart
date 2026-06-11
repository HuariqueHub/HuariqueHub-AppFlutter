import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/services/category_service.dart';
import '../../data/services/huarique_service.dart';
import '../../providers/auth_provider.dart';

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
  final _categoryService = CategoryService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;

  bool _loading = false;
  bool _loadingInitial = true;
  String? _error;

  bool get _isEditing => widget.huariqueId != null;

  @override
  void initState() {
    super.initState();
    _init();
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

  /// Carga las categorías desde la API y, si estamos editando, el huarique.
  Future<void> _init() async {
    setState(() => _loadingInitial = true);
    try {
      _categories = await _categoryService.getAll();
      _selectedCategory =
          _categories.isNotEmpty ? _categories.first : null;

      if (_isEditing) {
        final h = await _service.getById(widget.huariqueId!);
        _nameCtrl.text = h.name;
        _districtCtrl.text = h.district;
        _addressCtrl.text = h.address ?? '';
        _priceCtrl.text = h.price > 0 ? h.price.toStringAsFixed(0) : '';
        _descCtrl.text = h.description ?? '';
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == h.categoryId || c.name == h.category,
            orElse: () => _categories.first,
          );
        }
      }
    } catch (_) {
      _error = 'Error al cargar los datos del formulario.';
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _error = 'Selecciona una categoría.');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() { _loading = true; _error = null; });
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'category': _selectedCategory!.name,
        'categoryId': _selectedCategory!.id,
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
      if (mounted) setState(() => _loading = false);
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
      body: _loadingInitial
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
                      child: DropdownButtonFormField<Category>(
                        initialValue: _selectedCategory,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                        decoration: const InputDecoration(),
                        validator: (v) =>
                            v == null ? 'Selecciona una categoría' : null,
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
                            hintText: 'Ej. Av. La Marina 2355, San Miguel'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Con la dirección, tus clientes podrán abrir la ruta en Google Maps desde el detalle del local.',
                        style: TextStyle(fontSize: 11, color: kTextTertiary),
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
