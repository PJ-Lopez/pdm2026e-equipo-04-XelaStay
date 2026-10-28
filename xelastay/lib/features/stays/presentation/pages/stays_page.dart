import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/stay.dart';
import '../../domain/usecases/get_public_stays.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';

class StaysPage extends ConsumerStatefulWidget {
  const StaysPage({
    super.key,
    required this.user,
    required this.getPublicStays,
    required this.onOpenProfile,
  });

  final AppUser user;
  final GetPublicStays getPublicStays;
  final VoidCallback onOpenProfile;

  @override
  ConsumerState<StaysPage> createState() => _StaysPageState();
}

class _StaysPageState extends ConsumerState<StaysPage> {
  final _searchController = TextEditingController();
  final _updatingFavoriteIds = <String>{};
  late Future<List<Stay>> _staysFuture;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _staysFuture = widget.getPublicStays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = widget.getPublicStays();
    setState(() {
      _staysFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder muestra el estado de error en la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedStays = ref.watch(favoritesProvider).asData?.value;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _topBar(context),
              const SizedBox(height: 28),
              Text(
                'Tu próxima historia empieza en Xela.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 29,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Encuentra un espacio que se sienta tuyo en Quetzaltenango.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: '¿Qué te gustaría tener cerca?',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUETZALTENANGO, GUATEMALA',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Descubre Xela a tu manera',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 19),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Alojamientos locales para tu próxima visita.',
                              style: TextStyle(
                                color: AppColors.muted,
                                height: 1.35,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 112,
                      height: 142,
                      child: ImagePlaceholder(
                        label: 'Aquí va una imagen de Xela',
                        compact: true,
                        icon: Icons.landscape_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _search.isEmpty
                          ? 'Alojamientos para descubrir'
                          : 'Resultados',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 21),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar alojamientos',
                    onPressed: () => _refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Stay>>(
                future: _staysFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _CatalogLoading();
                  }
                  if (snapshot.hasError) {
                    return _CatalogMessage(
                      icon: Icons.wifi_off_outlined,
                      title: 'No pudimos cargar los alojamientos',
                      detail: 'Revisa tu conexión e inténtalo de nuevo.',
                      action: FilledButton.tonalIcon(
                        onPressed: () => _refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    );
                  }

                  final allStays = snapshot.data ?? const <Stay>[];
                  final stays = allStays.where(_matchesSearch).toList();
                  if (stays.isEmpty) {
                    return _CatalogMessage(
                      icon: Icons.home_work_outlined,
                      title: _search.isEmpty
                          ? 'Aún no hay alojamientos publicados'
                          : 'No encontramos resultados',
                      detail: _search.isEmpty
                          ? 'Vuelve pronto para conocer nuevos espacios en Xela.'
                          : 'Prueba con otro nombre, zona o referencia.',
                      action: FilledButton.tonalIcon(
                        onPressed: _search.isEmpty
                            ? () => _refresh()
                            : () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                        icon: Icon(
                          _search.isEmpty ? Icons.refresh : Icons.search_off,
                        ),
                        label: Text(
                          _search.isEmpty ? 'Actualizar' : 'Limpiar búsqueda',
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final stay in stays) ...[
                        _StayCard(
                          stay: stay,
                          isFavorite:
                              savedStays?.any((saved) => saved.id == stay.id) ??
                              stay.isFavorite,
                          isUpdatingFavorite: _updatingFavoriteIds.contains(
                            stay.id,
                          ),
                          onToggleFavorite: () => _toggleFavorite(stay),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Stay stay) async {
    if (_updatingFavoriteIds.contains(stay.id)) return;
    final favorites = ref.read(favoritesProvider).asData?.value;
    final isFavorite =
        favorites?.any((favorite) => favorite.id == stay.id) ?? stay.isFavorite;
    setState(() => _updatingFavoriteIds.add(stay.id));
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavorite(stay.id);
      } else {
        await repository.addFavorite(stay.id);
      }
      if (!mounted) return;
      ref.invalidate(favoritesProvider);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? 'Se quitó de tus guardados.'
                  : 'Se agregó a tus guardados.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar tus guardados.')),
      );
    } finally {
      if (mounted) setState(() => _updatingFavoriteIds.remove(stay.id));
    }
  }

  Widget _topBar(BuildContext context) => Row(
    children: [
      const Icon(Icons.place_outlined, color: AppColors.blue, size: 22),
      const SizedBox(width: 7),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explorando',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            Text(
              'Quetzaltenango, Guatemala',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Abrir perfil',
        onPressed: widget.onOpenProfile,
        icon: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.blueSoft,
          child: Text(
            _initials(widget.user.name),
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  bool _matchesSearch(Stay stay) {
    if (_search.isEmpty) return true;
    return '${stay.title} ${stay.zone} ${stay.reference} ${stay.propertyType}'
        .toLowerCase()
        .contains(_search);
  }
}

String _initials(String name) {
  final names = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final firstTwo = names.take(2).map((part) => part[0].toUpperCase()).join();
  return firstTwo.isEmpty ? 'X' : firstTwo;
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.stay,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onToggleFavorite,
  });

  final Stay stay;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StayImage(url: stay.coverPhotoUrl),
              Positioned(
                top: 9,
                right: 9,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: isUpdatingFavorite
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: isFavorite
                              ? 'Quitar de guardados'
                              : 'Agregar a guardados',
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.red : AppColors.muted,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stay.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 17),
                    ),
                  ),
                  if (stay.ratingCount > 0) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE8A638),
                      size: 19,
                    ),
                    const SizedBox(width: 3),
                    Text(stay.ratingAverage.toStringAsFixed(1)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stay.zone,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              if (stay.reference.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  stay.reference,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    stay.isVerified
                        ? Icons.verified_outlined
                        : Icons.place_outlined,
                    size: 17,
                    color: stay.isVerified
                        ? AppColors.success
                        : AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      stay.isVerified
                          ? 'Ubicación revisada'
                          : 'Ubicación pendiente de revisión',
                      style: TextStyle(
                        color: stay.isVerified
                            ? AppColors.success
                            : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${stay.currency == 'GTQ' ? 'Q' : stay.currency} ${stay.priceInCurrency.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Text(
                    ' / noche',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hasta ${stay.capacity} huéspedes · ${stay.propertyType}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StayImage extends StatelessWidget {
  const _StayImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ImagePlaceholder(
        label: 'Aquí va una imagen del alojamiento',
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const ImagePlaceholder(label: 'Aquí va una imagen del alojamiento'),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ImagePlaceholder(label: 'Cargando imagen', compact: true),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SizedBox(height: 24),
      CircularProgressIndicator(semanticsLabel: 'Cargando alojamientos'),
      SizedBox(height: 16),
      Text('Cargando alojamientos'),
      SizedBox(height: 24),
    ],
  );
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: AppColors.blue),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
