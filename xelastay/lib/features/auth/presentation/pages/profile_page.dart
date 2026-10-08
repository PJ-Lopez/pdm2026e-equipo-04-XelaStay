import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.authController,
    required this.onOpenHosts,
  });

  final AppUser user;
  final AuthController authController;
  final VoidCallback onOpenHosts;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi perfil')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ClipOval(
                  child: const SizedBox.square(
                    dimension: 116,
                    child: ImagePlaceholder(
                      label: 'Aquí va tu foto',
                      icon: Icons.person_outline,
                      compact: true,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(user.email, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionCard(
            title: 'Información de la cuenta',
            children: [
              _ProfileRow(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: user.name,
              ),
              _ProfileRow(
                icon: Icons.mail_outline,
                label: 'Correo electrónico',
                value: user.email,
              ),
              _ProfileRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: user.phone?.isNotEmpty == true ? user.phone! : 'Sin agregar',
              ),
              _ProfileRow(
                icon: Icons.badge_outlined,
                label: 'Tipo de cuenta',
                value: _roleLabel(user.role),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_work_outlined, color: AppColors.blue, size: 26),
                const SizedBox(height: 10),
                Text(
                  user.canManageStays
                      ? 'Administra tu alojamiento'
                      : '¿Tienes un alojamiento en Xela?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  user.canManageStays
                      ? 'Revisa tu panel y gestiona tus espacios.'
                      : 'Compártelo con viajeros y recibe nuevas visitas.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onOpenHosts,
                  icon: Icon(
                    user.canManageStays ? Icons.dashboard_outlined : Icons.add_home_outlined,
                  ),
                  label: Text(
                    user.canManageStays ? 'Ir al panel de anfitrión' : 'Conocer modo anfitrión',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: authController.isLoading ? null : authController.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _roleLabel(AppRole role) => switch (role) {
    AppRole.guest => 'Huésped',
    AppRole.host => 'Anfitrión',
    AppRole.admin => 'Administrador',
  };
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      if (showDivider) const Divider(height: 1, color: AppColors.line),
    ],
  );
}
