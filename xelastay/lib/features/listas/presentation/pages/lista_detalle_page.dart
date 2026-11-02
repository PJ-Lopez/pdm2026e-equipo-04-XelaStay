import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../stays/domain/entities/stay.dart';
import '../../domain/entities/alojamiento_guardado.dart';
import '../../domain/entities/lista.dart';
import '../providers/guardados_providers.dart';
import '../providers/listas_providers.dart';

/// Alojamientos guardados en una lista. Son los que hacen que la lista esté
/// "en uso" y no se pueda eliminar.
class ListaDetallePage extends ConsumerWidget {
  const ListaDetallePage({super.key, required this.lista});

  final Lista lista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardados = ref.watch(guardadosDeListaProvider(lista.id));
    return Scaffold(
      appBar: AppBar(title: Text(lista.nombre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregar(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar alojamiento'),
      ),
      body: guardados.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(guardadosDeListaProvider(lista.id)),
            child: const Text('No pudimos leer esta lista. Reintentar'),
          ),
        ),
        data: (alojamientos) => alojamientos.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Esta lista está vacía. Agrega alojamientos del catálogo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  for (final a in alojamientos)
                    ListTile(
                      leading: const Icon(
                        Icons.home_outlined,
                        color: AppColors.blue,
                      ),
                      title: Text(a.titulo),
                      subtitle: Text(
                        '${a.zona} · ${_quetzales(a.precioCentavos)} / noche',
                      ),
                      trailing: IconButton(
                        tooltip: 'Quitar de la lista',
                        icon: const Icon(Icons.bookmark_remove_outlined),
                        onPressed: () => _quitar(context, ref, a),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    final avisos = ScaffoldMessenger.of(context);
    final stay = await showModalBottomSheet<Stay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _CatalogoSheet(),
    );
    if (stay == null || !context.mounted) return;
    try {
      await ref
          .read(guardadosRepositoryProvider)
          .guardar(
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
      _refrescar(ref);
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Guardado en "${lista.nombre}"')),
        );
    } catch (_) {
      if (!context.mounted) return;
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

  Future<void> _quitar(
    BuildContext context,
    WidgetRef ref,
    AlojamientoGuardado alojamiento,
  ) async {
    final avisos = ScaffoldMessenger.of(context);
    try {
      await ref.read(guardadosRepositoryProvider).quitar(alojamiento.stayId);
      if (!context.mounted) return;
      _refrescar(ref);
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Alojamiento quitado')));
    } catch (_) {
      if (!context.mounted) return;
      avisos
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos quitar el alojamiento. Intenta de nuevo.',
            ),
          ),
        );
    }
  }

  // Cambia esta lista, el contador de la pantalla de listas y, si el
  // alojamiento venía de otra lista, también esa otra.
  void _refrescar(WidgetRef ref) {
    ref.invalidate(guardadosDeListaProvider);
    ref.invalidate(listasProvider);
  }
}

String _quetzales(int centavos) => centavos % 100 == 0
    ? 'Q ${centavos ~/ 100}'
    : 'Q ${(centavos / 100).toStringAsFixed(2)}';

/// Catálogo del API para elegir qué alojamiento guardar.
class _CatalogoSheet extends ConsumerWidget {
  const _CatalogoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: catalogo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(catalogoProvider),
            child: const Text('No pudimos cargar el catálogo. Reintentar'),
          ),
        ),
        data: (stays) => ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Elige un alojamiento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final s in stays)
              ListTile(
                title: Text(s.title),
                subtitle: Text(
                  '${s.zone} · ${_quetzales(s.priceAmount)} / noche',
                ),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
  }
}
