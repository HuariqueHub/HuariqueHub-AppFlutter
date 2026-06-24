import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';

/// Recuperación de contraseña (US16): solicitar instrucciones y restablecer.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _service = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  int _step = 1; // 1 = solicitar, 2 = restablecer
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; _message = null; });
    try {
      if (_step == 1) {
        final msg = await _service.forgotPassword(_emailCtrl.text.trim());
        setState(() { _message = msg; _step = 2; });
      } else {
        final msg =
            await _service.resetPassword(_emailCtrl.text.trim(), _passCtrl.text);
        setState(() => _message = msg);
      }
    } catch (e) {
      setState(() => _error = _extractError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extractError(Object e) {
    final s = e.toString();
    if (s.contains('404')) return 'No existe una cuenta con ese correo.';
    if (s.contains('400')) return 'Revisa los datos ingresados.';
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _emailCtrl.text.trim().isNotEmpty &&
        (_step == 1 || _passCtrl.text.length >= 6);
    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Recuperar contraseña',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: Text('🔑', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 12),
          Text(
            _step == 1
                ? 'Ingresa tu correo para recuperar el acceso.'
                : 'Define una nueva contraseña para tu cuenta.',
            style: const TextStyle(color: kTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
          ),
          if (_step == 2) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              onChanged: (_) => setState(() {}),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña (mín. 6)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: kBrownDark)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_loading || !canSubmit) ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(_step == 1
                    ? 'Enviar instrucciones'
                    : 'Restablecer contraseña'),
          ),
          if (_step == 2)
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Volver a iniciar sesión'),
            ),
        ],
      ),
    );
  }
}
