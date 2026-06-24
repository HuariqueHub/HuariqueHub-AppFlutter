import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/huarique.dart';
import '../../data/models/review.dart';
import '../../data/services/huarique_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/report_service.dart';
import '../../providers/auth_provider.dart';

class HuariqueDetailScreen extends StatefulWidget {
  final int huariqueId;
  const HuariqueDetailScreen({super.key, required this.huariqueId});

  @override
  State<HuariqueDetailScreen> createState() => _HuariqueDetailScreenState();
}

class _HuariqueDetailScreenState extends State<HuariqueDetailScreen> {
  final _service = HuariqueService();
  final _favoriteService = FavoriteService();
  final _reportService = ReportService();
  final _reviewCtrl = TextEditingController();

  Huarique? _huarique;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _isFavorite = false;
  int _myRating = 5;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getById(widget.huariqueId),
        _service.getReviews(widget.huariqueId),
      ]);
      _huarique = results[0] as Huarique;
      _reviews = results[1] as List<Review>;
    } catch (_) {
      // keep null — will show error UI
    } finally {
      setState(() => _loading = false);
    }
    await _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      final ids = await _favoriteService.getFavoriteIds(userId);
      if (mounted) setState(() => _isFavorite = ids.contains(widget.huariqueId));
    } catch (_) {
      // sin favoritos: no bloqueante
    }
  }

  /// Marca/desmarca como favorito (US03), optimista con reversión ante error.
  Future<void> _toggleFavorite() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final wasFavorite = _isFavorite;
    setState(() => _isFavorite = !wasFavorite);
    try {
      if (wasFavorite) {
        await _favoriteService.remove(userId, widget.huariqueId);
      } else {
        await _favoriteService.add(userId, widget.huariqueId);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = wasFavorite);
    }
  }

  Future<void> _submitReview() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _submittingReview = true);
    try {
      final review = await _service.addReview({
        'huariqueId': widget.huariqueId,
        'userId': auth.user!.id,
        'rating': _myRating,
        'comment': _reviewCtrl.text.trim(),
      });
      setState(() {
        _reviews.insert(0, review);
        _reviewCtrl.clear();
        _myRating = 5;
      });
    } catch (e) {
      if (mounted) {
        // Surface el mensaje de moderación del backend cuando aplica (US08).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_serverMessage(e) ?? 'Error al enviar la reseña')),
        );
      }
    } finally {
      setState(() => _submittingReview = false);
    }
  }

  /// Extrae el campo "message" del cuerpo de error del backend (ErrorResource).
  String? _serverMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    }
    return null;
  }

  /// Reporta información incorrecta del huarique (US21).
  Future<void> _submitReport(String reason) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      await _reportService.createReport(widget.huariqueId, userId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracias, registramos tu reporte para revisión.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_serverMessage(e) ?? 'No se pudo enviar el reporte')),
        );
      }
    }
  }

  void _showReportDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reportar información'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '¿Qué dato está incorrecto?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogCtx).pop();
              _submitReport(reason);
            },
            child: const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }

  /// Destino para Google Maps: usa coordenadas exactas si existen; si no,
  /// arma la dirección de texto (Maps la geolocaliza solo). Devuelve null
  /// cuando no hay suficiente información para ubicar el local.
  String? _mapsDestination() {
    final h = _huarique;
    if (h == null) return null;
    if (h.hasLocation) return '${h.latitude},${h.longitude}';

    final address = h.address?.trim() ?? '';
    if (address.isEmpty) return null;

    final district = h.district.trim();
    return district.isEmpty ? '$address, Perú' : '$address, $district, Perú';
  }

  /// Abre Google Maps con la ruta desde la ubicación actual del usuario
  /// hasta el huarique. No requiere permisos: Maps usa la posición del
  /// dispositivo como origen al omitir el parámetro de partida.
  Future<void> _openDirections() async {
    final destination = _mapsDestination();
    if (destination == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
    );

    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWarmWhite,
      appBar: AppBar(
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _huarique?.name ?? 'Detalle',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_huarique != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              tooltip: _isFavorite
                  ? 'Quitar de favoritos'
                  : 'Agregar a favoritos',
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kOrangePrimary))
          : _huarique == null
              ? const Center(child: Text('No se pudo cargar el huarique'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: kOrangeLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🍽️',
                                      style: TextStyle(fontSize: 32)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _huarique!.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: kBrownDark,
                                        ),
                                      ),
                                      Text(
                                        '${_huarique!.category} · ${_huarique!.district}',
                                        style: const TextStyle(
                                            color: kTextSecondary,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 15, color: kStarYellow),
                                          const SizedBox(width: 4),
                                          Text(
                                            _huarique!.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: kBrownDark,
                                            ),
                                          ),
                                          Text(
                                            ' (${_huarique!.reviewCount} reseñas)',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: kTextTertiary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_huarique!.openStatus != OpenStatus.unknown) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _huarique!.openStatus ==
                                              OpenStatus.open
                                          ? Colors.green.shade600
                                          : kTextTertiary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule,
                                            size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          _huarique!.openStatus.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_huarique!.openAt != null &&
                                      _huarique!.closeAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_huarique!.openAt} - ${_huarique!.closeAt}',
                                      style: const TextStyle(
                                          color: kTextSecondary, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if (_huarique!.price > 0) ...[
                              const SizedBox(height: 12),
                              const Divider(color: kDividerWarm),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 16, color: kOrangePrimary),
                                  Text(
                                    'Precio promedio: S/ ${_huarique!.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: kOrangePrimary,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                            if (_huarique!.address != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: kTextSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _huarique!.address!,
                                      style: const TextStyle(
                                          color: kTextSecondary,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_huarique!.description != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _huarique!.description!,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 14),
                              ),
                            ],
                            if (_mapsDestination() != null) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openDirections,
                                  icon: const Icon(Icons.directions,
                                      color: kOrangePrimary),
                                  label: const Text(
                                    'Cómo llegar',
                                    style: TextStyle(
                                        color: kOrangePrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: kOrangePrimary),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            // Reportar información incorrecta (US21)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _showReportDialog,
                                icon: const Icon(Icons.flag_outlined,
                                    size: 16, color: kTextSecondary),
                                label: const Text('Reportar información',
                                    style: TextStyle(
                                        fontSize: 12, color: kTextSecondary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Write review
                    const Text(
                      'Dejar una reseña',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kBrownDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Star selector
                            Row(
                              children: List.generate(
                                5,
                                (i) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _myRating = i + 1),
                                  child: Icon(
                                    i < _myRating
                                        ? Icons.star
                                        : Icons.star_outline,
                                    color: kStarYellow,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _reviewCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'Comparte tu experiencia...',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  borderSide:
                                      BorderSide(color: kDividerWarm),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  borderSide:
                                      BorderSide(color: kDividerWarm),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  borderSide:
                                      BorderSide(color: kOrangePrimary, width: 2),
                                ),
                                filled: true,
                                fillColor: kSurfaceColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submittingReview
                                    ? null
                                    : _submitReview,
                                child: _submittingReview
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Publicar reseña'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reviews list
                    Text(
                      'Reseñas (${_reviews.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kBrownDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Sé el primero en dejar una reseña.',
                          style: TextStyle(color: kTextTertiary),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...(_reviews.map((r) => _ReviewTile(review: r))),
                  ],
                ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: kOrangeLight,
                  child: Text(
                    (review.userName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: kOrangePrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  review.userName ?? 'Usuario',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: kBrownDark),
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_outline,
                      size: 14,
                      color: kStarYellow,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
