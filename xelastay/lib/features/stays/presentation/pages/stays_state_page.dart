import 'package:flutter/material.dart';
import '../../data/repositories/stays_state_repository.dart';

class StaysStatePage extends StatefulWidget {
  final IStaysStateRepository repository;

  const StaysStatePage({super.key, required this.repository});

  @override
  State<StaysStatePage> createState() => _StaysStatePageState();
}

class _StaysStatePageState extends State<StaysStatePage> {
  late Future<List<StayItem>> _futureStays;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureStays = widget.repository.fetchStays();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi pantalla'), centerTitle: true),
      body: FutureBuilder<List<StayItem>>(
        future: _futureStays,
        builder: (context, snapshot) {
          // 1. Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // 2. Error con mensaje amigable y botón Reintentar
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pudimos cargar los datos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ocurrió un error al consultar las estancias. Revisa tu conexión a internet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          // 3. Vacío con botón de acción
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.apartment_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aún no hay datos.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _recargar,
                    icon: const Icon(Icons.add),
                    label: const Text('+ Agregar'),
                  ),
                ],
              ),
            );
          }

          // 4. Datos
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final stay = data[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.home_work_outlined),
                ),
                title: Text(
                  stay.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(stay.location),
                trailing: Text(
                  'Q${stay.pricePerNight.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
