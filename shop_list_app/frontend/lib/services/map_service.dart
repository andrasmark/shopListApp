import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapService {
  static const apiKey = 'AIzaSyC3qxvbGlUDtZrqT6LPqNcySJR45OXAHiE';

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
      '&type=supermarket' // általános kulcsszó
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
