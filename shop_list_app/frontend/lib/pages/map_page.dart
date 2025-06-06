import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shop_list_app/pages/settings_page.dart';
import 'package:shop_list_app/services/groceryLists_service.dart';
import 'package:shop_list_app/services/map_service.dart';

import '../services/settings_service.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic>? groceryList;
  const MapPage({super.key, required this.groceryList});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _userLocation;
  GoogleMapController? _googleMapController;
  Set<Marker> _lidlMarkers = {};
  MapService _mapService = MapService();
  Polyline? _routePolyline;
  GrocerylistService _grocerylistService = GrocerylistService();
  bool _locationAllowed = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
    debugGetLocation();
  }

  Future<void> _drawRouteToStores(List<String> storeNames) async {
    if (_userLocation == null) return;

    Map<String, LatLng> storeLocations = {};

    for (final storeName in storeNames) {
      final markers = await _mapService.searchNearbyStores(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        storeName: storeName,
      );

      final nearestStorePos =
          _mapService.getNearestMarker(_userLocation!, markers);
      if (nearestStorePos != null) {
        storeLocations[storeName] = nearestStorePos;
      }
    }

    if (storeLocations.isEmpty) return;

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

    List<LatLng> routePoints = [];
    LatLng currentPoint = _userLocation!;
    Set<String> unvisitedStores = Set.from(storeLocations.keys);

    while (unvisitedStores.isNotEmpty) {
      String nearestStore = unvisitedStores.first;
      double nearestDistance =
          haversineDistance(currentPoint, storeLocations[nearestStore]!);

      for (final store in unvisitedStores) {
        final d = haversineDistance(currentPoint, storeLocations[store]!);
        if (d < nearestDistance) {
          nearestDistance = d;
          nearestStore = store;
        }
      }

      routePoints.add(storeLocations[nearestStore]!);
      unvisitedStores.remove(nearestStore);
      currentPoint = storeLocations[nearestStore]!;
    }

    setState(() {
      _routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: [_userLocation!, ...routePoints],
      );
    });
  }

  void debugGetLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(
        "------------------------------------------------------------------------------------------------------------------------------------");
    print("DEBUG LOCATION: ${position.latitude}, ${position.longitude}");
    print(
        "------------------------------------------------------------------------------------------------------------------------------------");
  }

  Future<void> _searchNearbyStores(String _storeName) async {
    if (_userLocation == null) return;

    try {
      final markers = await _mapService.searchNearbyStores(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        storeName: _storeName,
      );

      if (markers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No store found nearby")),
        );
        return;
      }

      setState(() {
        _lidlMarkers = markers.toSet();
      });

      if (_googleMapController != null) {
        final firstMarker = markers.first.position;
        _googleMapController!
            .animateCamera(CameraUpdate.newLatLngZoom(firstMarker, 14));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _locationAllowed = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final newLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _userLocation = newLocation;
      _locationAllowed = true;
    });
  }

  // Future<void> _getLocation() async {
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   LocationPermission permission = await Geolocator.checkPermission();
  //
  //   if (!serviceEnabled) {
  //     return;
  //   }
  //
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return;
  //     }
  //   }
  //
  //   final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   final newLocation = LatLng(position.latitude, position.longitude);
  //
  //   setState(() {
  //     _userLocation = newLocation;
  //   });
  //
  //   // Itt mozgatjuk a térképet a helyünkre
  //   //_mapController.move(newLocation, 15.0);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final settingsService = SettingsService();
              final locationEnabled =
                  await settingsService.getLocationAllowed();

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Settings"),
                  content: Text(
                    "Location: ${locationEnabled ? 'Enabled' : 'Disabled'}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: const Text("Settings"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: !_locationAllowed,
            child: Opacity(
              opacity: _locationAllowed ? 1.0 : 0.3,
              child: Column(
                children: [
                  // Térkép kártya stílusban
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        width: double.infinity,
                        child: _userLocation == null
                            ? const Center(child: CircularProgressIndicator())
                            : GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _userLocation!,
                                  zoom: 15.0,
                                ),
                                onMapCreated: (controller) {
                                  _googleMapController = controller;
                                },
                                polylines: _routePolyline != null
                                    ? {_routePolyline!}
                                    : {},
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('user'),
                                    position: _userLocation!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueRed),
                                  ),
                                  ..._lidlMarkers,
                                },
                              ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _searchNearbyStores('Lidl');
                        },
                        child: const Text('LIDL'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _searchNearbyStores('Auchan');
                        },
                        child: const Text('AUCHAN'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _searchNearbyStores('Carrefour');
                        },
                        child: const Text('CARREFOUR'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _searchNearbyStores('Kaufland');
                        },
                        child: const Text('KAUFLAND'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      print(
                          "START-----------------------------------------------------------------------------------------------------");
                      final groceryList = widget.groceryList!;
                      final requiredStores = await _grocerylistService
                          .getStoresForList(groceryList);
                      _drawRouteToStores(requiredStores);
                      print(groceryList);
                      print(requiredStores);
                      print(
                          "END-----------------------------------------------------------------------------------------------------");
                    },
                    child: const Text('Show Route'),
                  ),
                ],
              ),
            ),
          ),
          if (!_locationAllowed)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Location is disabled.\nPlease go to settings to enable it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                        },
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
