import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../stays/domain/entities/stay.dart';
import '../../domain/entities/reserva.dart';
import '../providers/reservas_providers.dart';
import '../widgets/desglose_card.dart';

/// Formulario para pedir una reserva: fechas, huéspedes y desglose. Al
/// enviarla hace `pop(true)` para que el detalle avise que se envió.
class SolicitarReservaPage extends ConsumerStatefulWidget {
  const SolicitarReservaPage({
    super.key,
    required this.stay,
    required this.usuario,
    this.fechasIniciales,
  });

  final Stay stay;
  final AppUser usuario;

  /// Para pruebas: arranca con fechas ya elegidas.
  final DateTimeRange? fechasIniciales;

  @override
  ConsumerState<SolicitarReservaPage> createState() =>
      _SolicitarReservaPageState();
}

class _SolicitarReservaPageState extends ConsumerState<SolicitarReservaPage> {
  late DateTimeRange? _fechas = widget.fechasIniciales;
  int _huespedes = 1;
  bool _enviando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final stay = widget.stay;
    final fechas = _fechas;
    final desglose = fechas == null
        ? null
        : Desglose.de(
            stay.priceAmount,
            fechas.end.difference(fechas.start).inDays,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar reserva')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(stay.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(stay.zone, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          Text('Fechas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _enviando ? null : _elegirFechas,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              fechas == null
                  ? 'Elegir fechas'
                  : rangoFechas(fechas.start, fechas.end),
            ),
          ),
          const SizedBox(height: 20),
          Text('Huéspedes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Menos huéspedes',
                onPressed: _huespedes > 1
                    ? () => setState(() {
                        if (_huespedes > 1) _huespedes--;
                      })
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_huespedes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.outlined(
                tooltip: 'Más huéspedes',
                onPressed: _huespedes < stay.capacity
                    ? () => setState(() {
                        if (_huespedes < stay.capacity) _huespedes++;
                      })
                    : null,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Máximo ${stay.capacity}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
          if (desglose != null) ...[
            const SizedBox(height: 24),
            DesgloseCard(
              precioNocheCentavos: stay.priceAmount,
              desglose: desglose,
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Es una solicitud: el anfitrión la revisa y, si la acepta, pagas '
            'para confirmar la estadía.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: fechas == null || _enviando ? null : _enviar,
            child: Text(_enviando ? 'Enviando…' : 'Enviar solicitud'),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirFechas() async {
    final hoy = soloFecha(ref.read(relojProvider)());
    final elegidas = await showDateRangePicker(
      context: context,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      initialDateRange: _fechas,
      helpText: 'Llegada y salida',
      saveText: 'Listo',
    );
    if (elegidas != null && mounted) {
      setState(() {
        _fechas = elegidas;
        _error = null;
      });
    }
  }

  Future<void> _enviar() async {
    final fechas = _fechas;
    // Guardia de doble toque: se revisa ANTES del primer await.
    if (fechas == null || _enviando) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    final repositorio = ref.read(reservasRepositoryProvider);
    try {
      await repositorio.solicitar(
        SolicitudReserva(
          stayId: widget.stay.id,
          titulo: widget.stay.title,
          zona: widget.stay.zone,
          precioNocheCentavos: widget.stay.priceAmount,
          capacidad: widget.stay.capacity,
          entrada: fechas.start,
          salida: fechas.end,
          huespedes: _huespedes,
          huespedId: widget.usuario.id,
          huespedNombre: widget.usuario.name,
        ),
      );
      if (!mounted) return;
      refrescarReservas(ref);
      Navigator.of(context).pop(true);
    } on ReservaException catch (e) {
      // Se conserva lo que la persona eligió; solo se muestra el motivo.
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos enviar la solicitud. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}
