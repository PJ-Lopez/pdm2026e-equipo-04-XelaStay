import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/centro_del_mapa.dart';
import '../../domain/entities/stay.dart';
import 'stay_detail_page.dart';

/// Mapa de Xela con un pin por alojamiento. Recibe la lista YA filtrada de
/// Explorar, así que conserva la búsqueda y los chips.
class MapaAlojamientosPage extends StatefulWidget {
  const MapaAlojamientosPage({
    super.key,
    required this.stays,
    required this.usuario,
    this.capaDeMapa,
  });

  final List<Stay> stays;
  final AppUser usuario;

  /// Las teselas de OpenStreetMap. Las pruebas pasan otra capa para no
  /// descargar imágenes de internet.
  final Widget? capaDeMapa;

  @override
  State<MapaAlojamientosPage> createState() => _MapaAlojamientosPageState();
}

class _MapaAlojamientosPageState extends State<MapaAlojamientosPage> {
  Stay? _elegido;

  @override
  Widget build(BuildContext context) {
    final conUbicacion = widget.stays.where((s) => s.tieneUbicacion).toList();
    final sinUbicacion = widget.stays.length - conUbicacion.length;
    final elegido = _elegido;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Xela')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: centroDelMapa(conUbicacion),
              initialZoom: 14,
              // Tocar fuera de un pin cierra la tarjeta.
              onTap: (_, _) => setState(() => _elegido = null),
            ),
            children: [
              widget.capaDeMapa ??
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.xelastay',
                  ),
              MarkerLayer(
                markers: [
                  for (final s in conUbicacion)
                    Marker(
                      point: LatLng(s.latitud!, s.longitud!),
                      width: 84,
                      height: 34,
                      child: _Pin(
                        stay: s,
                        elegido: identical(s, elegido),
                        onTap: () => setState(() => _elegido = s),
                      ),
                    ),
                ],
              ),
              // La licencia de OpenStreetMap pide mostrar el crédito.
              RichAttributionWidget(
  attributions: [
    TextSourceAttribution('OpenStreetMap contributors'),
  ],
)
        ]),
          if (conUbicacion.isEmpty || sinUbicacion > 0)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _Aviso(
                texto: conUbicacion.isEmpty
                    ? 'Estos alojamientos todavía no tienen ubicación en el '
                          'mapa. Míralos en la lista.'
                    : sinUbicacion == 1
                    ? '1 alojamiento no tiene ubicación y solo sale en la lista.'
                    : '$sinUbicacion alojamientos no tienen ubicación y solo '
                          'salen en la lista.',
              ),
            ),
          if (elegido != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 32,
              child: _TarjetaElegida(
                stay: elegido,
                onVerDetalle: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        StayDetailPage(stay: elegido, usuario: widget.usuario),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Q 250" del pin.
String _precioCorto(Stay s) =>
    '${s.currency == 'GTQ' ? 'Q' : s.currency} '
    '${s.priceInCurrency.toStringAsFixed(0)}';

class _Pin extends StatelessWidget {
  const _Pin({required this.stay, required this.elegido, required this.onTap});

  final Stay stay;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${stay.title}, ${_precioCorto(stay)} por noche',
    child: GestureDetector(
      key: ValueKey('pin-${stay.id}'),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: elegido ? AppColors.blue : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue, width: 1.5),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Text(
          _precioCorto(stay),
          style: TextStyle(
            color: elegido ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _TarjetaElegida extends StatelessWidget {
  const _TarjetaElegida({required this.stay, required this.onVerDetalle});

  final Stay stay;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 4,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stay.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${stay.zone} · ${_precioCorto(stay)} / noche',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (!stay.isVerified) ...[
            const SizedBox(height: 4),
            const Text(
              'Ubicación pendiente de revisión: el pin es aproximado.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onVerDetalle,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver detalle'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 2,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    ),
  );
}
