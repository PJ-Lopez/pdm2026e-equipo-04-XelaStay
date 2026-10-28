import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../stays/domain/entities/stay.dart';
import '../providers/favorites_providers.dart';

class GuardadosPage extends ConsumerStatefulWidget {
  const GuardadosPage({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  ConsumerState<GuardadosPage> createState() => _GuardadosPageState();
}

class _GuardadosPageState extends ConsumerState<GuardadosPage> {
  final _searchController = TextEditingController();
  final _removingIds = <String>{};
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: AppColors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text('XelaStay'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar guardados',
          onPressed: () => ref.invalidate(favoritesProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ref
          .watch(favoritesProvider)
          .when(
            loading: () => const _LoadingState(),
            error: (_, _) =>
                _ErrorState(onRetry: () => ref.invalidate(favoritesProvider)),
            data: _buildFavorites,
          ),
    ),
  );

  Widget _buildFavorites(List<Stay> stays) {
    final filtered = stays.where(_matchesSearch).toList(growable: false);
    if (stays.isEmpty) return _EmptyState(onExplore: widget.onExplore);
    if (filtered.isEmpty) {
      return _NoSearchResults(
        query: _search,
        onClear: () {
          _searchController.clear();
          setState(() => _search = '');
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(favoritesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MIS COLECCIONES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                  color: AppColors.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stays.length} ${stays.length == 1 ? 'estancia' : 'estancias'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Tus Guardados',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          const Text(
            'Alojamientos que guardaste para tu próxima visita a Quetzaltenango.',
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar en tus guardados',
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
          const SizedBox(height: 16),
          for (final stay in filtered)
            _SavedStayCard(
              stay: stay,
              isRemoving: _removingIds.contains(stay.id),
              onRemove: () => _removeFavorite(stay),
            ),
        ],
      ),
    );
  }

  bool _matchesSearch(Stay stay) =>
      _search.isEmpty ||
      '${stay.title} ${stay.zone} ${stay.reference} ${stay.propertyType}'
          .toLowerCase()
          .contains(_search);

  Future<void> _removeFavorite(Stay stay) async {
    setState(() => _removingIds.add(stay.id));
    try {
      await ref.read(favoritesRepositoryProvider).removeFavorite(stay.id);
      if (!mounted) return;
      ref.invalidate(favoritesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${stay.title} se quitó de tus guardados.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo quitar. Inténtalo de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _removingIds.remove(stay.id));
    }
  }
}

class _SavedStayCard extends StatelessWidget {
  const _SavedStayCard({
    required this.stay,
    required this.isRemoving,
    required this.onRemove,
  });

  final Stay stay;
  final bool isRemoving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 194,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StayImage(url: stay.coverPhotoUrl),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .93),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.landscape_rounded,
                        size: 14,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stay.zone,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: isRemoving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Quitar de guardados',
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.red,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (stay.isVerified) ...[
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Ubicación verificada por XelaStay',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (stay.ratingCount > 0) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${stay.ratingAverage.toStringAsFixed(1)} (${stay.ratingCount})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stay.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                stay.reference.isEmpty
                    ? stay.zone
                    : '${stay.zone} · ${stay.reference}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const Divider(height: 23),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${stay.currency == 'GTQ' ? 'Q' : stay.currency} ${stay.priceInCurrency.toStringAsFixed(0)} ',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const TextSpan(
                          text: '/ noche',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${stay.capacity} huéspedes · ${stay.propertyType}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
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

class _StayImage extends StatelessWidget {
  const _StayImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ImagePlaceholder(label: 'Foto del alojamiento');
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const ImagePlaceholder(label: 'Foto del alojamiento'),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const ImagePlaceholder(label: 'Cargando foto', compact: true),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.red),
        SizedBox(height: 14),
        Text('Cargando tus estancias guardadas'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 56,
            color: AppColors.red,
          ),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar tus guardados',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Revisa tu conexión e inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 58,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          Text(
            'Aún no tienes estancias guardadas',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          const Text(
            'Guarda alojamientos que te interesen y aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explorar alojamientos'),
          ),
        ],
      ),
    ),
  );
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay guardados que coincidan con “$query”',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            label: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    ),
  );
}
