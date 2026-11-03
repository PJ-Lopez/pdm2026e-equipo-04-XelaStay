import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../data/repositories/resenas_repository_impl.dart';
import '../../domain/entities/resena.dart';
import '../providers/resenas_providers.dart';
import '../widgets/estrellas.dart';

/// Formulario para reseñar una estadía completada. Al publicar cierra y
/// devuelve la reseña guardada.
class ResenaPage extends ConsumerStatefulWidget {
  const ResenaPage({super.key, required this.reserva});

  final Reserva reserva;

  @override
  ConsumerState<ResenaPage> createState() => _ResenaPageState();
}

class _ResenaPageState extends ConsumerState<ResenaPage> {
  final _comentario = TextEditingController();
  int _estrellas = 0;
  bool _publicando = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñar estadía')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(r.titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            rangoFechas(r.entrada, r.salida),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          const Text(
            '¿Cómo te fue?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: i == 1 ? '1 estrella' : '$i estrellas',
                  onPressed: _publicando
                      ? null
                      : () => setState(() {
                          _estrellas = i;
                          _error = null;
                        }),
                  icon: Icon(
                    i <= _estrellas
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: colorEstrella,
                    size: 34,
                  ),
                ),
            ],
          ),
          Text(
            _estrellas == 0
                ? 'Toca las estrellas para calificar.'
                : '$_estrellas de 5 · ${etiquetaEstrellas(_estrellas)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _comentario,
            minLines: 3,
            maxLines: 6,
            maxLength: ResenasRepositoryImpl.largoMaximo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: 'Cuéntale a otros huéspedes cómo te fue',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _estrellas == 0 || _publicando ? null : _publicar,
            child: Text(_publicando ? 'Publicando…' : 'Publicar reseña'),
          ),
        ],
      ),
    );
  }

  Future<void> _publicar() async {
    // Guardia de doble toque: se revisa ANTES del primer await.
    if (_publicando) return;
    setState(() {
      _publicando = true;
      _error = null;
    });
    final repositorio = ref.read(resenasRepositoryProvider);
    try {
      final resena = await repositorio.publicar(
        reservaId: widget.reserva.id,
        estrellas: _estrellas,
        comentario: _comentario.text,
      );
      if (!mounted) return;
      refrescarResenas(ref, resena);
      Navigator.of(context).pop(resena);
    } on ResenaException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos publicar la reseña. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }
}
