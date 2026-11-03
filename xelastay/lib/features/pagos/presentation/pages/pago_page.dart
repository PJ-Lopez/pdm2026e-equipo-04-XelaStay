import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../../booking/presentation/providers/reservas_providers.dart';
import '../../../booking/presentation/widgets/desglose_card.dart';
import '../../domain/entities/pago.dart';
import '../providers/pagos_providers.dart';

/// Pago SIMULADO de una reserva aceptada. No pide datos de tarjeta: solo el
/// método. Al pagar hace `pop(pago)` y la reserva queda confirmada.
class PagoPage extends ConsumerStatefulWidget {
  const PagoPage({super.key, required this.reserva});

  final Reserva reserva;

  @override
  ConsumerState<PagoPage> createState() => _PagoPageState();
}

class _PagoPageState extends ConsumerState<PagoPage> {
  MetodoPago? _metodo;
  bool _pagando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final desglose = r.desglose;
    final metodo = _metodo;
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar reserva')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(r.titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            rangoFechas(r.entrada, r.salida),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          DesgloseCard(
            precioNocheCentavos: r.precioNocheCentavos,
            desglose: desglose,
          ),
          const SizedBox(height: 22),
          Text(
            'Método de pago',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final m in MetodoPago.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icono(m), color: AppColors.blue),
              title: Text(m.etiqueta),
              trailing: Icon(
                m == metodo ? Icons.check_circle : Icons.circle_outlined,
                color: m == metodo ? AppColors.blue : AppColors.muted,
              ),
              selected: m == metodo,
              onTap: _pagando ? null : () => setState(() => _metodo = m),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pago simulado: no se hace ningún cobro real ni se piden '
                    'datos de tarjeta.',
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: metodo == null || _pagando ? null : _pagar,
            child: Text(
              _pagando
                  ? 'Pagando…'
                  : 'Pagar ${quetzales(desglose.totalCentavos)}',
            ),
          ),
        ],
      ),
    );
  }

  IconData _icono(MetodoPago m) => switch (m) {
    MetodoPago.tarjeta => Icons.credit_card,
    MetodoPago.transferencia => Icons.account_balance_outlined,
    MetodoPago.efectivo => Icons.payments_outlined,
  };

  Future<void> _pagar() async {
    final metodo = _metodo;
    // Guardia de doble toque: se revisa ANTES del primer await.
    if (metodo == null || _pagando) return;
    setState(() {
      _pagando = true;
      _error = null;
    });
    final repositorio = ref.read(pagosRepositoryProvider);
    try {
      final pago = await repositorio.pagar(widget.reserva.id, metodo);
      if (!mounted) return;
      refrescarReservas(ref);
      ref.invalidate(pagoDeReservaProvider);
      Navigator.of(context).pop(pago);
    } on PagoException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos registrar el pago. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }
}
