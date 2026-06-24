import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/huarique.dart';
import '../../data/services/huarique_service.dart';
import '../../data/services/favorite_service.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = HuariqueService();
  final _favoriteService = FavoriteService();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'Todos';
  List<Huarique> _huariques = [];
  List<Huarique> _filtered = [];
  Set<int> _favoriteIds = {};
  List<Huarique> _suggestions = [];
  bool _nearbyOnly = false;
  bool _favoritesOnly = false;
  bool _loading = true;
  String? _error;

  // Las categorías se derivan de los datos reales cargados desde el backend,
  // de modo que cada chip siempre corresponde a huariques existentes.
  List<String> get _categories {
    final cats = _huariques.map((h) => h.category).where((c) => c.isNotEmpty).toSet().toList()
      ..sort();
    return ['Todos', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _huariques = await _service.getAll(near: _nearbyOnly);
      _applyFilter();
      await _loadFavorites();
      await _loadSuggestions();
    } catch (e) {
      setState(() => _error = 'Error al cargar los datos. Verifica tu conexión.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      final ids = await _favoriteService.getFavoriteIds(userId);
      if (mounted) setState(() => _favoriteIds = ids);
    } catch (_) {
      // Sin favoritos disponibles: no es un error bloqueante.
    }
  }

  Future<void> _loadSuggestions() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      final list = await _service.getSuggestions(userId);
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      // Sin sugerencias: no es un error bloqueante.
    }
  }

  /// Marca/desmarca un favorito (US03) con actualización optimista y reversión.
  Future<void> _toggleFavorite(int huariqueId) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final wasFavorite = _favoriteIds.contains(huariqueId);
    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(huariqueId);
      } else {
        _favoriteIds.add(huariqueId);
      }
      _applyFilter();
    });
    try {
      if (wasFavorite) {
        await _favoriteService.remove(userId, huariqueId);
      } else {
        await _favoriteService.add(userId, huariqueId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(huariqueId);
        } else {
          _favoriteIds.remove(huariqueId);
        }
        _applyFilter();
      });
    }
  }

  Future<void> _toggleNearby() async {
    setState(() => _nearbyOnly = !_nearbyOnly);
    await _load();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    _filtered = _huariques.where((h) {
      final matchCat =
          _selectedCategory == 'Todos' || h.category == _selectedCategory;
      final matchSearch = q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.district.toLowerCase().contains(q);
      final matchFav = !_favoritesOnly || _favoriteIds.contains(h.id);
      return matchCat && matchSearch && matchFav;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kWarmWhite,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: kBrownDark,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kBrownDark, kBrownMedium],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: kOrangePrimary, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'HuariqueHub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Hola, ${auth.user?.name.split(' ').first ?? 'visitante'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.map_outlined,
                              color: Colors.white),
                          tooltip: 'Ver en mapa',
                          onPressed: () => context.push('/map'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          tooltip: 'Notificaciones',
                          onPressed: () => context.push('/notifications'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          tooltip: 'Preferencias',
                          onPressed: () => context.push('/preferences'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_outline,
                              color: Colors.white),
                          tooltip: 'Cerrar sesión',
                          onPressed: () {
                            context.read<AuthProvider>().logout();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: kBrownDark,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(_applyFilter),
                  decoration: InputDecoration(
                    hintText: 'Buscar huarique...',
                    prefixIcon: const Icon(Icons.search, color: kTextTertiary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: kTextPrimary),
                ),
              ),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _applyFilter();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? kOrangePrimary : kSurfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? kOrangePrimary : kDividerWarm,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : kTextSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Sugeridos para ti (US18)
          if (_suggestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Sugeridos para ti ✨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kBrownDark,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return GestureDetector(
                          onTap: () => context.push('/huarique/${s.id}'),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kSurfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kDividerWarm),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kBrownDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.category} · ${s.district}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: kTextSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 13, color: kStarYellow),
                                    const SizedBox(width: 3),
                                    Text(s.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 12, color: kBrownDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Filtros rápidos: Cerca de mí (US19) y Favoritos (US03)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Cerca de mí'),
                    avatar: Icon(
                      Icons.near_me,
                      size: 18,
                      color: _nearbyOnly ? Colors.white : kOrangePrimary,
                    ),
                    selected: _nearbyOnly,
                    onSelected: (_) => _toggleNearby(),
                    selectedColor: kOrangePrimary,
                    labelStyle: TextStyle(
                      color: _nearbyOnly ? Colors.white : kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Favoritos'),
                    avatar: Icon(
                      _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _favoritesOnly ? Colors.white : kOrangePrimary,
                    ),
                    selected: _favoritesOnly,
                    onSelected: (v) =>
                        setState(() { _favoritesOnly = v; _applyFilter(); }),
                    selectedColor: kOrangePrimary,
                    labelStyle: TextStyle(
                      color: _favoritesOnly ? Colors.white : kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    showCheckmark: false,
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: kOrangePrimary),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: kTextTertiary),
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: kTextSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No se encontraron resultados.',
                    style: TextStyle(color: kTextSecondary)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HuariqueCard(
                      huarique: _filtered[i],
                      isFavorite: _favoriteIds.contains(_filtered[i].id),
                      onToggleFavorite: () => _toggleFavorite(_filtered[i].id),
                      onTap: () =>
                          context.push('/huarique/${_filtered[i].id}'),
                    ),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HuariqueCard extends StatelessWidget {
  final Huarique huarique;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;
  const _HuariqueCard({
    required this.huarique,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = huarique.openStatus;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🍽️', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            huarique.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: kBrownDark,
                            ),
                          ),
                        ),
                        if (status != OpenStatus.unknown)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == OpenStatus.open
                                  ? Colors.green.shade600
                                  : kTextTertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status == OpenStatus.open ? 'Abierto' : 'Cerrado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (huarique.hasPromo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kOrangePrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${huarique.category} · ${huarique.district}',
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: kStarYellow),
                        const SizedBox(width: 3),
                        Text(
                          huarique.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kBrownDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${huarique.reviewCount})',
                          style: const TextStyle(
                              fontSize: 11, color: kTextTertiary),
                        ),
                        const Spacer(),
                        if (huarique.price > 0)
                          Text(
                            'S/ ${huarique.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kOrangePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: isFavorite ? Colors.red : kTextTertiary,
                ),
                tooltip: isFavorite
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
