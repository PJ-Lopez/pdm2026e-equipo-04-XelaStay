import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lista.dart';
import '../providers/listas_providers.dart';
import '../widgets/lista_form.dart';

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
        data: (todas) => todas.isEmpty
            ? const _SinListas()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [for (final l in todas) _ListaTile(lista: l)],
              ),
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
      leading: const CircleAvatar(
        backgroundColor: AppColors.blueSoft,
        child: Icon(Icons.bookmark_outline, color: AppColors.blue),
      ),
      title: Text(lista.nombre),
      subtitle: Text(_resumen(lista)),
      trailing: const Icon(Icons.edit_outlined, color: AppColors.muted),
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
        ref.invalidate(listasProvider);
      },
    ),
  );
  if (mensaje != null && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
