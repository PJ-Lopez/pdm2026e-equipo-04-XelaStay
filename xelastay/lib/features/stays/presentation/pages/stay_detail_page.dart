import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../booking/presentation/pages/solicitar_reserva_page.dart';
import '../../../listas/domain/entities/alojamiento_guardado.dart';
import '../../../listas/domain/entities/lista.dart';
import '../../../listas/presentation/pages/listas_page.dart';
import '../../../listas/presentation/providers/guardados_providers.dart';
import '../../../listas/presentation/providers/listas_providers.dart';
import '../../domain/entities/stay.dart';
import '../widgets/stay_photo.dart';

/// Detalle de un alojamiento del catálogo. Los datos llegan del API en la
/// lista de Explorar; desde aquí se guarda en una lista o se pide reserva.
class StayDetailPage extends ConsumerWidget {
  const StayDetailPage({super.key, required this.stay, required this.usuario});

  final Stay stay;

  /// Quién está usando la app: la solicitud de reserva va a su nombre.
  final AppUser usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Alojamiento')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: StayPhoto(url: stay.coverPhotoUrl),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          stay.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 25, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          stay.reference.isEmpty
              ? stay.zone
              : '${stay.zone} · ${stay.reference}',
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        _Calificacion(stay: stay),
        const SizedBox(height: 18),
        _Verificacion(verificado: stay.isVerified),
        const SizedBox(height: 18),
        _Dato(
          icono: Icons.people_outline,
          texto: 'Hasta ${stay.capacity} huéspedes',
        ),
        _Dato(icono: Icons.home_outlined, texto: stay.propertyType),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: precioPorNoche(stay),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const TextSpan(
                          text: ' / noche',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _guardarEnLista(context, ref),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => _solicitarReserva(context),
              child: const Text('Solicitar reserva'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _solicitarReserva(BuildContext context) async {
    final avisos = ScaffoldMessenger.of(context);
    final enviada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SolicitarReservaPage(stay: stay, usuario: usuario),
      ),
    );
    if (enviada == true) {
      avisos.showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada. Síguela en la pestaña Reservas.'),
        ),
      );
    }
  }

  /// Guarda el alojamiento en la lista que elija el usuario. Después se
  /// invalidan los providers para que Guardados muestre lo que quedó en la
  /// base (no se agrega a mano).
  Future<void> _guardarEnLista(BuildContext context, WidgetRef ref) async {
    final avisos = ScaffoldMessenger.of(context);
    final guardados = ref.read(guardadosRepositoryProvider);
    final lista = await showModalBottomSheet<Lista>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _ElegirListaSheet(),
    );
    if (lista == null || !context.mounted) return;
    try {
      await guardados.guardar(
        AlojamientoGuardado(
          stayId: stay.id,
          titulo: stay.title,
          zona: stay.zone,
          precioCentavos: stay.priceAmount,
          guardadoEn: DateTime.now(),
          listaId: lista.id,
        ),
      );
      if (!context.mounted) return;
      ref.invalidate(listasProvider);
      ref.invalidate(guardadosDeListaProvider);
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Guardado en "${lista.nombre}"')),
        );
    } catch (_) {
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos guardar el alojamiento. Intenta de nuevo.',
            ),
          ),
        );
    }
  }
}

/// "Q 250" a partir del precio en centavos del API.
String precioPorNoche(Stay stay) =>
    '${stay.currency == 'GTQ' ? 'Q' : stay.currency} '
    '${stay.priceInCurrency.toStringAsFixed(0)}';

class _Calificacion extends StatelessWidget {
  const _Calificacion({required this.stay});

  final Stay stay;

  @override
  Widget build(BuildContext context) {
    // Sin reseñas no se inventa un promedio.
    if (stay.ratingCount == 0) {
      return const Text(
        'Aún sin reseñas',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final n = stay.ratingCount;
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFE8A638), size: 20),
        const SizedBox(width: 4),
        Text(
          '${stay.ratingAverage.toStringAsFixed(1)} · '
          '${n == 1 ? '1 reseña' : '$n reseñas'}',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Verificacion extends StatelessWidget {
  const _Verificacion({required this.verificado});

  final bool verificado;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: verificado ? const Color(0xFFE8F3EE) : AppColors.canvas,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          verificado ? Icons.verified_outlined : Icons.place_outlined,
          color: verificado ? AppColors.success : AppColors.muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verificado
                    ? 'Ubicación revisada por XelaStay'
                    : 'Ubicación pendiente de revisión',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                verificado
                    ? 'El equipo confirmó la dirección y las referencias.'
                    : 'Todavía no confirmamos la dirección; usa las '
                          'referencias como guía.',
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icono, color: AppColors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}

/// Hoja para elegir en qué lista guardar. Solo ofrece listas activas.
class _ElegirListaSheet extends ConsumerWidget {
  const _ElegirListaSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listas = ref.watch(listasProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: listas.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: TextButton(
              onPressed: () => ref.invalidate(listasProvider),
              child: const Text('No pudimos leer tus listas. Reintentar'),
            ),
          ),
          data: (todas) {
            final activas = todas.where((l) => !l.archivada).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Guardar en…',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (activas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      'Aún no tienes listas activas.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                for (final l in activas)
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.blue,
                    ),
                    title: Text(l.nombre),
                    subtitle: Text(
                      l.alojamientos == 1
                          ? '1 alojamiento'
                          : '${l.alojamientos} alojamientos',
                    ),
                    onTap: () => Navigator.of(context).pop(l),
                  ),
                TextButton.icon(
                  onPressed: () => abrirFormularioLista(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva lista'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
