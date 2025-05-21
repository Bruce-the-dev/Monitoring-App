import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> animateMarkerMovement({
  required Marker oldMarker,
  required LatLng newPos,
  required void Function(Marker marker) onUpdate,
  required BitmapDescriptor icon,
  required VoidCallback onTap,
}) async {
  const duration = Duration(milliseconds: 1000);
  const steps = 30;
  final oldPos = oldMarker.position;
  final stepDuration = duration.inMilliseconds ~/ steps;

  for (int i = 0; i <= steps; i++) {
    final lat =
        oldPos.latitude + (newPos.latitude - oldPos.latitude) * i / steps;
    final lng =
        oldPos.longitude + (newPos.longitude - oldPos.longitude) * i / steps;
    final newMarker = Marker(
      markerId: oldMarker.markerId,
      position: LatLng(lat, lng),
      icon: icon,
      infoWindow: InfoWindow(
        title: oldMarker.infoWindow.title,
        snippet: oldMarker.infoWindow.snippet,
        onTap: onTap,
      ),
    );
    onUpdate(newMarker);
    await Future.delayed(Duration(milliseconds: stepDuration));
  }
}
