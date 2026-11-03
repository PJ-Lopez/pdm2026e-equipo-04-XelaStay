import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../domain/entities/mensaje.dart';
import '../providers/chat_providers.dart';

/// Chat de una reserva. Muestra de qué alojamiento y fechas se habla, y cada
/// mensaje con su autor y su hora (no solo con colores).
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.reserva, required this.comoAutor});

  final Reserva reserva;

  /// Desde dónde se abrió: el huésped (Reservas) o el anfitrión (Solicitudes).
  final AutorMensaje comoAutor;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _texto = TextEditingController();
  bool _enviando = false;
  String? _error;

  bool get _cerrada =>
      widget.reserva.estado == EstadoReserva.cancelada ||
      widget.reserva.estado == EstadoReserva.rechazada;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final mensajes = ref.watch(mensajesProvider(r.id));
    final otro = widget.comoAutor == AutorMensaje.huesped
        ? 'el anfitrión'
        : r.huespedNombre;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat con $otro', style: const TextStyle(fontSize: 17)),
            Text(
              '${r.titulo} · ${rangoFechas(r.entrada, r.salida)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: mensajes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(mensajesProvider(r.id)),
                  child: const Text('No pudimos leer los mensajes. Reintentar'),
                ),
              ),
              data: (lista) => lista.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Aún no hay mensajes. Escribe el primero para '
                          'coordinar tu estadía.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  : ListView(
                      // Al revés: arranca abajo, donde está lo más nuevo.
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      children: [
                        for (final m in lista.reversed)
                          _Burbuja(
                            mensaje: m,
                            propio: m.autor == widget.comoAutor,
                          ),
                      ],
                    ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red),
              ),
            ),
          SafeArea(
            top: false,
            child: _cerrada
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Esta reserva se cerró; el chat queda solo para leer.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _texto,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          tooltip: 'Enviar',
                          onPressed: _texto.text.trim().isEmpty || _enviando
                              ? null
                              : _enviar,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    // Guardia de doble toque: se revisa ANTES del primer await.
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    final repositorio = ref.read(chatRepositoryProvider);
    try {
      await repositorio.enviar(
        reservaId: widget.reserva.id,
        autor: widget.comoAutor,
        texto: _texto.text,
      );
      if (!mounted) return;
      // Solo se borra el texto cuando se guardó de verdad.
      _texto.clear();
      ref.invalidate(mensajesProvider(widget.reserva.id));
    } on ChatException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      // El borrador se queda en el campo para reintentar.
      if (mounted) {
        setState(
          () =>
              _error = 'No se envió. Tu mensaje sigue aquí; intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, required this.propio});

  final Mensaje mensaje;
  final bool propio;

  @override
  Widget build(BuildContext context) => Align(
    alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: propio ? AppColors.blueSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${propio ? 'Tú' : mensaje.autor.etiqueta} · '
            '${fechaHora(mensaje.enviadoEn)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(mensaje.texto),
        ],
      ),
    ),
  );
}
