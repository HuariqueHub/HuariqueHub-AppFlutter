import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.owner => 'Dueño',
    UserRole.admin => 'Administrador',
    _ => 'Explorador',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        foregroundColor: Colors.white,
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar perfil',
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No hay sesión activa.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 48,
              backgroundColor: kOrangePrimary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kBrownDark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kOrangeLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(user.role),
                style: const TextStyle(
                  color: kOrangeDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: user.email.isNotEmpty
                        ? user.email
                        : 'No disponible',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'ID de usuario',
                    value: '#${user.id}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: kErrorRed),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: kErrorRed),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: kErrorRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kOrangePrimary),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: kTextSecondary)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, color: kBrownDark, fontWeight: FontWeight.w500)),
    );
  }
}