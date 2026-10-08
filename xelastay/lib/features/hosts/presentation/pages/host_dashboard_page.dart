import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/volcano_mark.dart';
import 'create_host_stay_page.dart';

class HostDashboardPage extends StatelessWidget {
  const HostDashboardPage({
    super.key,
    required this.user,
    required this.authController,
    required this.createStay,
  });

  final AppUser user;
  final AuthController authController;
  final Future<void> Function(BuildContext context) createStay;

  @override
  Widget build(BuildContext context) {
    final isHost = user.canManageStays;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anfitriones'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authController.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(alignment: Alignment.centerRight, child: VolcanoMark(size: 112)),
                  Text(
                    isHost ? 'Tu lugar en Xela puede ser especial.' : 'Comparte la Xela que conoces.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 27, height: 1.14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isHost
                        ? 'Registra tu alojamiento con ubicación y referencias locales. El equipo revisará los datos antes de publicarlo.'
                        : 'Recibe viajeros, cuéntales qué hace único tu espacio y ayúdales a conocer Quetzaltenango.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _HostBenefit(icon: Icons.place_outlined, title: 'Ubicación con referencias', detail: 'Ayuda a las personas a entender dónde está tu espacio.'),
            _HostBenefit(icon: Icons.verified_outlined, title: 'Revisión antes de publicar', detail: 'Cada alojamiento inicia como pendiente de verificación.'),
            _HostBenefit(icon: Icons.chat_bubble_outline, title: 'Comunicación directa', detail: 'Conversa con huéspedes sobre su estadía.'),
            if (authController.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(authController.errorMessage!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 20),
            if (isHost)
              FilledButton.icon(
                onPressed: () => createStay(context),
                icon: const Icon(Icons.add_home_outlined),
                label: const Text('Registrar alojamiento'),
              )
            else
              FilledButton(
                onPressed: authController.isLoading
                    ? null
                    : () async {
                        final activated = await authController.activateHostMode();
                        if (activated && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Modo anfitrión activado')),
                          );
                        }
                      },
                child: authController.isLoading
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Quiero ser anfitrión'),
              ),
            const SizedBox(height: 12),
            if (isHost) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue),
                    SizedBox(width: 12),
                    Expanded(child: Text('Al registrar tu espacio, quedará en revisión. Aún no aparecerá en el catálogo hasta ser verificado.', style: TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HostBenefit extends StatelessWidget {
  const _HostBenefit({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: AppColors.blue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(detail, style: const TextStyle(color: AppColors.muted, height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}
