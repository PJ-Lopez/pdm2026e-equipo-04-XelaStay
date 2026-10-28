import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/guardados_provider.dart';
import '../../domain/entities/saved_stay.dart';

class GuardadosScreen extends ConsumerStatefulWidget {
  const GuardadosScreen({super.key});

  @override
  ConsumerState<GuardadosScreen> createState() => _GuardadosScreenState();
}

class _GuardadosScreenState extends ConsumerState<GuardadosScreen> {
  int _currentNavIndex = 1;

  @override
  Widget build(BuildContext context) {
    final asyncStays = ref.watch(savedStaysApiProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'XelaStay',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: asyncStays.when(
        skipLoadingOnReload:
            false, // Evita ocultar el loader al recargar en Riverpod 3
        // ESTADO 1: CARGANDO[cite: 4, 5]
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFDC2626)),
              SizedBox(height: 16),
              Text('Cargando estancias desde xela-stayAPI...'),
            ],
          ),
        ),

        // ESTADO 2: ERROR CON REINTENTAR FUNCIONAL[cite: 4, 5]
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No pudimos cargar los datos.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(savedStaysApiProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),

        // ESTADO 3 Y 4: VACÍO Y DATOS[cite: 4, 5]
        data: (stays) {
          // ESTADO 3: VACÍO[cite: 4, 5]
          if (stays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Aún no tienes estancias guardadas.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(savedStaysApiProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar a guardados'),
                  ),
                ],
              ),
            );
          }

          // ESTADO 4: DATOS[cite: 4, 5]
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MIS COLECCIONES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stays.length} Estancias',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tus Guardados',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Colecciones para tu próxima visita a Quetzaltenango.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Filtros Horizontales
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                      label: const Text(
                        'Nueva lista',
                        style: TextStyle(color: Color(0xFF0F172A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Todos (${stays.length})',
                      isSelected: selectedFilter == 'Todos',
                      onTap: () =>
                          ref.read(selectedFilterProvider.notifier).state =
                              'Todos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ...stays.map((stay) => _buildStayCard(context, stay)),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFDC2626),
        unselectedItemColor: const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Guardados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildStayCard(BuildContext context, SavedStay stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  stay.imageUrl,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 210,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(
                      Icons.hotel,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              if (stay.featureBadge != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.landscape_rounded,
                          size: 14,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stay.featureBadge!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (stay.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ubicación verificada por XelaStay',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stay.rating} (${stay.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  stay.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stay.distanceText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Q${stay.pricePerNight.toInt()} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const TextSpan(
                            text: '/ noche',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Ver fechas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
