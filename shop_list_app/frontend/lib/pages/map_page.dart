import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shop_list_app/services/map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _userLocation;
  GoogleMapController? _googleMapController;
  Set<Marker> _lidlMarkers = {};
  MapService _mapService = MapService();

  @override
  void initState() {
    super.initState();
    _getLocation();
    debugGetLocation();
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

    if (!serviceEnabled) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final newLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _userLocation = newLocation;
    });

    // Itt mozgatjuk a térképet a helyünkre
    //_mapController.move(newLocation, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Add settings page
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Settings"),
                  content: const Text("Itt lesznek a beállítások."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Bezárás"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
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
          const Text(
            'Ide jönnek majd a gombok vagy egyéb funkciók',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
