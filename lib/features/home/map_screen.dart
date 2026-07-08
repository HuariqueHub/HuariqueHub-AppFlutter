import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/huarique_image.dart';
import '../../data/models/huarique.dart';
import '../../data/services/huarique_service.dart';

/// Mapa in-app con marcadores de huariques (US02).
///
/// Usa tiles de OpenStreetMap (sin API key). Solo se muestran los huariques
/// que tienen coordenadas válidas; al tocar un marcador se presenta un
/// resumen con nombre, dirección, calificación e imagen.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _service = HuariqueService();
  static const _limaCenter = LatLng(-12.0464, -77.0428);

  List<Huarique> _located = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await _service.getAll();
      _located = all.where((h) => h.hasLocation).toList();
    } catch (_) {
      _error = 'No se pudo cargar el mapa. Verifica tu conexión.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSummary(Huarique h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWarmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + nombre
            Row(
              children: [
                HuariqueImage(
                  url: h.imageUrl,
                  width: 60,
                  height: 60,
                  radius: 12,
                  emojiSize: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kBrownDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${h.category} · ${h.district}',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (h.address != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(h.address!,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: kStarYellow),
                const SizedBox(width: 4),
                Text(
                  '${h.rating.toStringAsFixed(1)} (${h.reviewCount})',
                  style: const TextStyle(
                      color: kBrownDark, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/huarique/${h.id}');
                },
                child: const Text('Ver detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrownDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Huariques en el mapa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kOrangePrimary))
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: kTextTertiary),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : FlutterMap(
        options: MapOptions(
          initialCenter: _located.isNotEmpty
              ? LatLng(_located.first.latitude!,
              _located.first.longitude!)
              : _limaCenter,
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.huariquehub.app',
          ),
          MarkerLayer(
            markers: [
              for (final h in _located)
                Marker(
                  point: LatLng(h.latitude!, h.longitude!),
                  width: 52,
                  height: 70,
                  child: GestureDetector(
                    onTap: () => _showSummary(h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: kOrangePrimary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: HuariqueImage(
                              url: h.imageUrl,
                              width: 46,
                              height: 46,
                              radius: 0,
                              emojiSize: 20,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            color: kOrangePrimary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}