import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../models/gistag_models.dart';
import '../../providers/app_providers.dart';

class NearbyPlacesMapPanel extends StatefulWidget {
  const NearbyPlacesMapPanel({
    super.key,
    required this.center,
    required this.places,
    required this.canUseNaverMap,
    required this.height,
    this.isLoading = false,
    this.statusMessage,
    this.onExpand,
  });

  final GeoPoint center;
  final List<Place> places;
  final bool canUseNaverMap;
  final double height;
  final bool isLoading;
  final String? statusMessage;
  final VoidCallback? onExpand;

  @override
  State<NearbyPlacesMapPanel> createState() => _NearbyPlacesMapPanelState();
}

class _NearbyPlacesMapPanelState extends State<NearbyPlacesMapPanel> {
  NaverMapController? _controller;
  NOverlayImage? _pinIcon;
  Place? _selectedPlace;

  @override
  void didUpdateWidget(covariant NearbyPlacesMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedPlace = _selectedPlace;
    if (selectedPlace != null &&
        !widget.places.any((place) => place.id == selectedPlace.id)) {
      _selectedPlace = null;
    }
    if (oldWidget.center != widget.center ||
        oldWidget.places != widget.places ||
        oldWidget.canUseNaverMap != widget.canUseNaverMap) {
      _syncMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GistagColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.canUseNaverMap
                  ? _buildNaverMap()
                  : _FallbackMap(places: widget.places, onSelect: _selectPlace),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: _MapTopBar(
                isLoading: widget.isLoading,
                message: widget.statusMessage ?? '핀을 눌러 운동 장소를 확인하세요.',
                count: widget.places.length,
                onExpand: widget.onExpand,
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: _panelBottomInset(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _selectedPlace == null
                    ? const SizedBox.shrink()
                    : _FloatingPlaceInfo(
                        key: ValueKey(_selectedPlace!.id),
                        place: _selectedPlace!,
                        onClose: () => setState(() => _selectedPlace = null),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaverMap() {
    final target = NLatLng(widget.center.latitude, widget.center.longitude);
    return NaverMap(
      forceGesture: true,
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: target, zoom: 15),
        locationButtonEnable: true,
        compassEnable: true,
        indoorEnable: false,
        scaleBarEnable: false,
        contentPadding: EdgeInsets.fromLTRB(
          0,
          76,
          0,
          134 + MediaQuery.viewPaddingOf(context).bottom,
        ),
      ),
      onMapReady: (controller) {
        _controller = controller;
        _syncMap();
      },
      onMapTapped: (_, _) {
        if (_selectedPlace != null) {
          setState(() => _selectedPlace = null);
        }
      },
    );
  }

  Future<void> _syncMap() async {
    final controller = _controller;
    if (controller == null || !widget.canUseNaverMap) {
      return;
    }

    final pinIcon = _pinIcon ??= await NOverlayImage.fromWidget(
      context: context,
      size: const Size(38, 55),
      widget: const _PinIcon(),
    );
    if (!mounted) {
      return;
    }

    final center = NLatLng(widget.center.latitude, widget.center.longitude);
    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: center, zoom: 15),
    );
    await controller.clearOverlays(type: NOverlayType.marker);

    final markers = widget.places
        .where((place) => place.latitude != null && place.longitude != null)
        .map((place) {
          final marker = NMarker(
            id: place.id,
            position: NLatLng(place.latitude!, place.longitude!),
            icon: pinIcon,
            size: const Size(38, 55),
            isHideCollidedMarkers: true,
          );
          marker.setOnTapListener((_) {
            _selectPlace(place);
            controller.updateCamera(
              NCameraUpdate.scrollAndZoomTo(
                target: NLatLng(place.latitude!, place.longitude!),
                zoom: 16,
              ),
            );
          });
          return marker;
        })
        .toSet();

    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
  }

  void _selectPlace(Place place) {
    setState(() => _selectedPlace = place);
  }

  double _panelBottomInset(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return 16 + (safeBottom > 0 ? 6 : 0);
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.isLoading,
    required this.message,
    required this.count,
    this.onExpand,
  });

  final bool isLoading;
  final String message;
  final int count;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.location_on_rounded,
                color: GistagColors.primary,
                size: 20,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 0 ? message : '$count개 장소 · $message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GistagColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onExpand != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: '지도보기',
                onPressed: () {
                  unawaited(
                    ProviderScope.containerOf(context, listen: false)
                        .read(analyticsServiceProvider)
                        .trackButton(
                          'nearby_map_expand',
                          properties: {
                            'screen': _analyticsScreen(context),
                            'component': 'icon_button',
                            'action_type': 'navigate',
                            'destination': '/places-map',
                          },
                        ),
                  );
                  onExpand?.call();
                },
                icon: const Icon(Icons.open_in_full_rounded),
                color: GistagColors.primary,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FloatingPlaceInfo extends StatelessWidget {
  const _FloatingPlaceInfo({super.key, required this.place, this.onClose});

  final Place place;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final meta = [
      place.workoutType,
      if (place.distance.isNotEmpty) place.distance,
      if (place.estimatedDurationMinutes != null)
        '${place.estimatedDurationMinutes}분 루틴',
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GistagColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: GistagColors.primarySoft.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.nfc_rounded,
                color: GistagColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GistagColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GistagColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (place.distanceText?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 3),
                    Text(
                      place.distanceText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GistagColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '닫기',
              onPressed: () {
                unawaited(
                  ProviderScope.containerOf(context, listen: false)
                      .read(analyticsServiceProvider)
                      .trackButton(
                        'nearby_map_place_close',
                        properties: {
                          'component': 'icon_button',
                          'screen': _analyticsScreen(context),
                          'action_type': 'close',
                        },
                      ),
                );
                onClose?.call();
              },
              icon: const Icon(Icons.close_rounded),
              color: GistagColors.mutedText,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

String _analyticsScreen(BuildContext context) {
  try {
    return GoRouterState.of(context).name ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

class _PinIcon extends StatelessWidget {
  const _PinIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 55,
      child: SvgPicture.asset(
        'assets/images/pin_icon.svg',
        width: 38,
        height: 55,
      ),
    );
  }
}

class _FallbackMap extends StatefulWidget {
  const _FallbackMap({required this.places, required this.onSelect});

  final List<Place> places;
  final ValueChanged<Place> onSelect;

  @override
  State<_FallbackMap> createState() => _FallbackMapState();
}

class _FallbackMapState extends State<_FallbackMap> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _MapCanvas()),
        for (var index = 0; index < widget.places.take(5).length; index++)
          _FallbackPin(
            index: index,
            place: widget.places[index],
            onTap: () => widget.onSelect(widget.places[index]),
          ),
      ],
    );
  }
}

class _FallbackPin extends StatelessWidget {
  const _FallbackPin({
    required this.index,
    required this.place,
    required this.onTap,
  });

  final int index;
  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positions = [
      const Alignment(-0.58, -0.22),
      const Alignment(0.36, -0.06),
      const Alignment(-0.02, 0.32),
      const Alignment(0.62, 0.22),
      const Alignment(-0.44, 0.48),
    ];

    return Align(
      alignment: positions[index % positions.length],
      child: GestureDetector(onTap: onTap, child: const _PinIcon()),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapCanvasPainter());
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8F3F2),
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.20),
      Offset(size.width * 0.92, size.height * 0.08),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.58),
      Offset(size.width * 0.95, size.height * 0.44),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, -20),
      Offset(size.width * 0.45, size.height * 0.82),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.02),
      Offset(size.width * 0.58, size.height * 0.90),
      road,
    );

    final green = Paint()..color = const Color(0xFFE8F4EC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.36, 118, 82),
        const Radius.circular(28),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, size.height * 0.14, 108, 76),
        const Radius.circular(24),
      ),
      green,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
