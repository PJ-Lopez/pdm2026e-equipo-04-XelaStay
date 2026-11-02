import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lista.dart';
import '../providers/listas_providers.dart';
import '../widgets/lista_form.dart';
import 'lista_detalle_page.dart';

class ListasPage extends ConsumerWidget {
  const ListasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listas = ref.watch(listasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis listas de viaje')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormularioLista(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva lista'),
      ),
      body: listas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(listasProvider),
            child: const Text('No pudimos leer tus listas. Reintentar'),
          ),
        ),
        data: (todas) {
          if (todas.isEmpty) return const _SinListas();
          final archivadas = todas.where((l) => l.archivada);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final l in todas.where((l) => !l.archivada))
                _ListaTile(lista: l),
              if (archivadas.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Text(
                    'Archivadas',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final l in archivadas) _ListaTile(lista: l),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ListaTile extends ConsumerWidget {
  const _ListaTile({required this.lista});

  final Lista lista;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    elevation: 0,
    color: AppColors.surface,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      leading: CircleAvatar(
        backgroundColor: lista.archivada
            ? AppColors.canvas
            : AppColors.blueSoft,
        child: Icon(
          lista.archivada ? Icons.inventory_2_outlined : Icons.bookmark_outline,
          color: lista.archivada ? AppColors.muted : AppColors.blue,
        ),
      ),
      title: Text(
        lista.nombre,
        style: TextStyle(
          color: lista.archivada ? AppColors.muted : AppColors.ink,
        ),
      ),
      subtitle: Text(_resumen(lista)),
      trailing: IconButton(
        tooltip: 'Ver alojamientos',
        icon: const Icon(Icons.chevron_right),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ListaDetallePage(lista: lista),
          ),
        ),
      ),
      // Tocar el registro abre el formulario lleno para editarlo.
      onTap: () => abrirFormularioLista(context, ref, lista: lista),
    ),
  );
}

String _resumen(Lista lista) {
  final n = lista.alojamientos;
  final cuantos = n == 1 ? '1 alojamiento' : '$n alojamientos';
  return lista.descripcion.isEmpty
      ? cuantos
      : '$cuantos · ${lista.descripcion}';
}

class _SinListas extends StatelessWidget {
  const _SinListas();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Aún no tienes listas. Crea una para guardar los alojamientos '
        'que te gustan.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

/// Abre el formulario para crear (`lista == null`) o editar una lista.
///
/// Después de guardar se INVALIDA el provider: la pantalla vuelve a leer de
/// la base, así lo que se ve es siempre lo que quedó guardado.
Future<void> abrirFormularioLista(
  BuildContext context,
  WidgetRef ref, {
  Lista? lista,
}) async {
  final repositorio = ref.read(listasRepositoryProvider);
  // Se toma ANTES de abrir el formulario: al archivar o eliminar, la fila que
  // se tocó cambia de lugar o desaparece y su `context` deja de servir.
  final avisos = ScaffoldMessenger.of(context);
  void refrescar() => ref.invalidate(listasProvider);

  final mensaje = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => ListaForm(
      lista: lista,
      onGuardar: (datos) async {
        await repositorio.guardar(
          id: lista?.id,
          nombre: datos.nombre,
          descripcion: datos.descripcion,
        );
        refrescar();
      },
      onArchivar: lista == null
          ? null
          : () async {
              await repositorio.archivar(lista.id, archivada: !lista.archivada);
              refrescar();
            },
      // Si la lista está en uso, eliminar lanza ListaException: el formulario
      // muestra el mensaje y la lista no se toca.
      onEliminar: lista == null
          ? null
          : () async {
              await repositorio.eliminar(lista.id);
              refrescar();
            },
    ),
  );
  if (mensaje != null) {
    avisos
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
