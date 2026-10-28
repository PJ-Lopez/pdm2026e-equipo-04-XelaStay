import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/booking/presentation/pages/reservations_page.dart';

/// Entrada independiente para revisar la pantalla de reservas con datos mock.
void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'XelaStay · Reservas de demostración',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const ReservationsPage(),
      ),
    ),
  );
}
