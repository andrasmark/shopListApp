import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapService {
  static const apiKey = 'YOUR_API_KEY';

  double haversineDistance(LatLng pos1, LatLng pos2) {
    const R = 6371e3;
    final lat1 = pos1.latitude * pi / 180;
    final lat2 = pos2.latitude * pi / 180;
    final deltaLat = (pos2.latitude - pos1.latitude) * pi / 180;
    final deltaLon = (pos2.longitude - pos1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = R * c;

    return distance;
  }

  LatLng? getNearestMarker(LatLng from, List<Marker> markers) {
    if (markers.isEmpty) return null;

    double haversineDistance(LatLng a, LatLng b) {
      const R = 6371e3; // méter
      final lat1 = a.latitude * pi / 180;
      final lat2 = b.latitude * pi / 180;
      final deltaLat = (b.latitude - a.latitude) * pi / 180;
      final deltaLon = (b.longitude - a.longitude) * pi / 180;

      final havA = sin(deltaLat / 2) * sin(deltaLat / 2) +
          cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
      final c = 2 * atan2(sqrt(havA), sqrt(1 - havA));

      return R * c;
    }

    LatLng nearest = markers.first.position;
    double minDistance = haversineDistance(from, nearest);

    for (final marker in markers) {
      final dist = haversineDistance(from, marker.position);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = marker.position;
      }
    }

    return nearest;
  }

  Future<List<Marker>> searchNearbyStores({
    required double latitude,
    required double longitude,
    required String storeName,
    int radiusInMeters = 30000,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$latitude,$longitude'
      '&radius=$radiusInMeters'
      '&keyword=$storeName'
      '&type=supermarket'
      '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Hiba történt a boltok lekérésekor: HTTP ${response.statusCode}',
      );
    }

    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('API hiba: ${data['status']}');
    }

    final results = data['results'] as List;
    final filteredResults = results.where((place) {
      final name = (place['name'] ?? '').toString().toLowerCase();
      final types = (place['types'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase()) ??
          [];

      return name.contains(storeName.toLowerCase()) ||
          types.any((t) => t.contains(storeName.toLowerCase()));
    }).toList();

    return filteredResults.map((place) {
      final location = place['geometry']['location'];
      final lat = location['lat'];
      final lon = location['lng'];

      return Marker(
        markerId: MarkerId('$lat,$lon'),
        position: LatLng(lat, lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: place['name'],
          snippet: place['vicinity'],
        ),
      );
    }).toList();
  }
}
