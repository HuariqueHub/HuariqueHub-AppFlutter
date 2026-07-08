import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: context.read<AuthProvider>().user?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? kErrorRed : Colors.green.shade600,
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      _snack('El nombre debe tener al menos 2 caracteres.', error: true);
      return;
    }
    final ok = await context.read<AuthProvider>().updateName(name);
    if (!mounted) return;
    _snack(ok ? 'Nombre actualizado.' : 'No se pudo actualizar el nombre.',
        error: !ok);
  }

  Future<void> _savePassword() async {
    final pass = _passCtrl.text;
    if (pass.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres.', error: true);
      return;
    }
    if (pass != _confirmCtrl.text) {
      _snack('Las contraseñas no coinciden.', error: true);
      return;
    }
    final ok = await context.read<AuthProvider>().changePassword(pass);
    if (!mounted) return;
    if (ok) {
      _passCtrl.clear();
      _confirmCtrl.clear();
    }
    _snack(ok ? 'Contraseña actualizada.' : 'No se pudo cambiar la contraseña.',
        error: !ok);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
            '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: kErrorRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    if (ok) {
      context.go('/login');
    } else {
      _snack('No se pudo eliminar la cuenta.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        foregroundColor: Colors.white,
        title: const Text('Editar perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nombre',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kBrownDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Tu nombre',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: loading ? null : _saveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangePrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar nombre'),
            ),
            const Divider(height: 40),
            const Text('Cambiar contraseña',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kBrownDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Nueva contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Confirmar contraseña',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: loading ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangePrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cambiar contraseña'),
            ),
            const Divider(height: 40),
            OutlinedButton.icon(
              onPressed: loading ? null : _deleteAccount,
              icon: const Icon(Icons.delete_outline, color: kErrorRed),
              label: const Text('Eliminar cuenta',
                  style: TextStyle(color: kErrorRed)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: kErrorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}