import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/app_user.dart';
import 'features/stays/data/repositories/simulated_stays_repository.dart';
import 'features/stays/domain/usecases/get_public_stays.dart';
import 'features/stays/presentation/pages/stays_page.dart';

/// Entrada independiente para el laboratorio; no reemplaza el API de main.dart.
void main() {
  const scenarioName = String.fromEnvironment(
    'STAYS_SCENARIO',
    defaultValue: 'data',
  );
  final scenario = StaysScenario.values.byName(scenarioName);
  runApp(
    MaterialApp(
      title: 'XelaStay · Catálogo de demostración',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: StaysPage(
        user: const AppUser(
          id: 'demo',
          name: 'Visitante de Xela',
          email: 'demo@example.com',
          role: AppRole.guest,
        ),
        getPublicStays: GetPublicStays(
          SimulatedStaysRepository(scenario: scenario),
        ),
        onOpenProfile: () {},
      ),
    ),
  );
}
