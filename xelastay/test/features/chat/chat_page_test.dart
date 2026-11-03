import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/presentation/pages/reserva_detalle_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/chat/domain/entities/mensaje.dart';
import 'package:xelastay/features/chat/domain/repositories/chat_repository.dart';
import 'package:xelastay/features/chat/presentation/pages/chat_page.dart';
import 'package:xelastay/features/chat/presentation/providers/chat_providers.dart';

void main() {
  testWidgets('el huésped abre el chat desde su reserva y escribe', (
    tester,
  ) async {
    final chat = _Chat();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reservaPorIdProvider.overrideWith(
            (ref, id) async => _reserva(EstadoReserva.pendiente),
          ),
          chatRepositoryProvider.overrideWithValue(chat),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ReservaDetallePage(reservaId: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chat con el anfitrión'));
    await tester.pumpAndSettle();

    expect(find.text('Chat con el anfitrión'), findsOneWidget);
    expect(
      find.text(
        'Aún no hay mensajes. Escribe el primero para coordinar tu estadía.',
      ),
      findsOneWidget,
    );
    final enviar = find.widgetWithIcon(IconButton, Icons.send);
    // Sin texto no se puede enviar.
    expect(tester.widget<IconButton>(enviar).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '¿Hay parqueo?');
    await tester.pump();
    await tester.tap(enviar);
    await tester.pumpAndSettle();

    expect(chat.enviados, [(7, AutorMensaje.huesped, '¿Hay parqueo?')]);
    expect(find.text('¿Hay parqueo?'), findsOneWidget); // ya en la lista
    expect(find.textContaining('Tú · '), findsOneWidget);
    // El campo se vacía solo después de guardar.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('el anfitrión ve quién escribió cada mensaje', (tester) async {
    final chat = _Chat()
      ..mensajes.addAll([
        _mensaje(1, AutorMensaje.huesped, '¿Puedo llegar tarde?'),
        _mensaje(2, AutorMensaje.anfitrion, 'Sí, te espero.'),
      ]);
    await _abrirChat(tester, chat, AutorMensaje.anfitrion);

    expect(find.text('Chat con Ana López'), findsOneWidget);
    expect(find.textContaining('Huésped · '), findsOneWidget);
    expect(find.textContaining('Tú · '), findsOneWidget);
  });

  testWidgets('si no se envía, el mensaje se queda para reintentar', (
    tester,
  ) async {
    final chat = _Chat()..fallar = true;
    await _abrirChat(tester, chat, AutorMensaje.huesped);

    await tester.enterText(find.byType(TextField), 'Llego el viernes');
    await tester.pump();
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se envió. Tu mensaje sigue aquí; intenta de nuevo.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Llego el viernes',
    );
  });

  testWidgets('una reserva cancelada deja el chat solo para leer', (
    tester,
  ) async {
    final chat = _Chat()
      ..mensajes.add(_mensaje(1, AutorMensaje.huesped, 'Gracias'));
    await _abrirChat(
      tester,
      chat,
      AutorMensaje.huesped,
      estado: EstadoReserva.cancelada,
    );

    expect(find.text('Gracias'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('Esta reserva se cerró; el chat queda solo para leer.'),
      findsOneWidget,
    );
  });

  testWidgets('si no se pueden leer los mensajes, ofrece reintentar', (
    tester,
  ) async {
    final chat = _Chat()..fallarAlLeer = true;
    await _abrirChat(tester, chat, AutorMensaje.huesped);

    expect(
      find.text('No pudimos leer los mensajes. Reintentar'),
      findsOneWidget,
    );

    chat.fallarAlLeer = false;
    await tester.tap(find.text('No pudimos leer los mensajes. Reintentar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Aún no hay mensajes. Escribe el primero para coordinar tu estadía.',
      ),
      findsOneWidget,
    );
  });
}

Reserva _reserva(EstadoReserva estado) => Reserva(
  id: 7,
  stayId: 'centro',
  titulo: 'Apartamento en el centro de Xela',
  zona: 'Zona 1',
  precioNocheCentavos: 25000,
  entrada: DateTime(2026, 11, 14),
  salida: DateTime(2026, 11, 16),
  huespedes: 2,
  huespedId: 'ana',
  huespedNombre: 'Ana López',
  estado: estado,
  creadaEn: DateTime(2026, 11, 2),
);

Mensaje _mensaje(int id, AutorMensaje autor, String texto) => Mensaje(
  id: id,
  reservaId: 7,
  autor: autor,
  texto: texto,
  enviadoEn: DateTime(2026, 11, 10, 9, id),
);

Future<void> _abrirChat(
  WidgetTester tester,
  _Chat chat,
  AutorMensaje comoAutor, {
  EstadoReserva estado = EstadoReserva.aceptada,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(chat)],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: ChatPage(reserva: _reserva(estado), comoAutor: comoAutor),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Chat en memoria: guarda lo que se envía y puede simular fallas.
class _Chat implements ChatRepository {
  final mensajes = <Mensaje>[];
  final enviados = <(int, AutorMensaje, String)>[];
  bool fallar = false;
  bool fallarAlLeer = false;

  @override
  Future<List<Mensaje>> mensajesDe(int reservaId) async {
    if (fallarAlLeer) throw Exception('sin base');
    return [...mensajes];
  }

  @override
  Future<Mensaje> enviar({
    required int reservaId,
    required AutorMensaje autor,
    required String texto,
  }) async {
    if (fallar) throw Exception('disco lleno');
    enviados.add((reservaId, autor, texto));
    final m = _mensaje(mensajes.length + 1, autor, texto);
    mensajes.add(m);
    return m;
  }
}
