import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lista.dart';

typedef DatosLista = ({String nombre, String descripcion});

/// El MISMO formulario crea (`lista == null`) y edita (`lista != null`).
///
/// No conoce SQL ni providers: recibe el registro inicial y las funciones
/// para guardar, archivar y eliminar. Al terminar hace `pop` con el mensaje
/// para el SnackBar.
class ListaForm extends StatefulWidget {
  const ListaForm({
    super.key,
    this.lista,
    required this.onGuardar,
    this.onArchivar,
    this.onEliminar,
  });

  final Lista? lista;
  final Future<void> Function(DatosLista datos) onGuardar;

  /// Archiva o restaura (según `lista.archivada`). Solo al editar.
  final Future<void> Function()? onArchivar;

  /// Solo al editar. Si la lista está en uso lanza [ListaException] y el
  /// mensaje queda visible junto al botón "Archivar".
  final Future<void> Function()? onEliminar;

  @override
  State<ListaForm> createState() => _ListaFormState();
}

class _ListaFormState extends State<ListaForm> {
  late final _nombre = TextEditingController(text: widget.lista?.nombre);
  late final _descripcion = TextEditingController(
    text: widget.lista?.descripcion,
  );
  bool _ocupado = false;
  String? _error;

  bool get _editando => widget.lista != null;
  bool get _archivada => widget.lista?.archivada ?? false;

  @override
  void initState() {
    super.initState();
    // Para habilitar o deshabilitar el botón mientras se escribe.
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    required String mensaje,
  }) async {
    // Guardia de doble toque: se revisa ANTES del primer await.
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
      if (mounted) Navigator.of(context).pop(mensaje);
    } on ListaException catch (e) {
      // Mensaje humano (nombre repetido, lista en uso...): el formulario
      // sigue abierto para que el usuario lo corrija o elija otra salida.
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _editando ? 'Editar lista' : 'Nueva lista',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nombre,
          autofocus: !_editando,
          maxLength: Lista.largoMaximoNombre,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Fin de semana en Xela',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descripcion,
          minLines: 1,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            hintText: 'Ej. Viaje con mis papás en diciembre',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _nombre.text.trim().isEmpty || _ocupado
              ? null
              : () => _ejecutar(
                  () => widget.onGuardar((
                    nombre: _nombre.text,
                    descripcion: _descripcion.text,
                  )),
                  mensaje: _editando ? 'Cambios guardados' : 'Lista creada',
                ),
          child: Text(_editando ? 'Guardar cambios' : 'Crear lista'),
        ),
        if (_editando)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (widget.onArchivar != null)
                TextButton.icon(
                  onPressed: _ocupado
                      ? null
                      : () => _ejecutar(
                          widget.onArchivar!,
                          mensaje: _archivada
                              ? 'Lista restaurada'
                              : 'Lista archivada',
                        ),
                  icon: Icon(
                    _archivada
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(_archivada ? 'Restaurar' : 'Archivar'),
                ),
              if (widget.onEliminar != null)
                TextButton.icon(
                  onPressed: _ocupado
                      ? null
                      : () => _ejecutar(
                          widget.onEliminar!,
                          mensaje: 'Lista eliminada',
                        ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
            ],
          ),
      ],
    ),
  );
}
