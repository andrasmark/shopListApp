// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
//
// class MapPage extends StatefulWidget {
//   const MapPage({super.key});
//
//   @override
//   State<MapPage> createState() => _MapPageState();
// }
//
// class _MapPageState extends State<MapPage> {
//   LatLng? _userLocation;
//
//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//   }
//
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       await Geolocator.openLocationSettings();
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//       if (permission != LocationPermission.whileInUse &&
//           permission != LocationPermission.always) {
//         return;
//       }
//     }
//
//     final pos = await Geolocator.getCurrentPosition();
//     setState(() {
//       _userLocation = LatLng(pos.latitude, pos.longitude);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Your Location")),
//       body: _userLocation == null
//           ? const Center(child: CircularProgressIndicator())
//           : Container(
//               margin: const EdgeInsets.all(16),
//               height: 400,
//               child: FlutterMap(
//                 options: MapOptions(
//                   center: _userLocation,
//                   zoom: 15.0,
//                 ),
//                 children: [
//                   TileLayer(
//                     urlTemplate:
//                         'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                     userAgentPackageName: 'com.example.app',
//                   ),
//                   MarkerLayer(
//                     markers: [
//                       Marker(
//                         width: 60,
//                         height: 60,
//                         point: _userLocation!,
//                         child: const Icon(
//                           Icons.person_pin_circle,
//                           size: 50,
//                           color: Colors.blue,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
//
// // class MapPage extends StatefulWidget {
// //   final String listId;
// //   const MapPage({super.key, required this.listId});
// //
// //   @override
// //   State<MapPage> createState() => _MapPageState();
// // }
// //
// // class _MapPageState extends State<MapPage> {
// //   GoogleMapController? _mapController;
// //   LatLng? _userLocation;
// //   List<LatLng> _storeLocations = [];
// //   Set<Polyline> _polylines = {};
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initLocationAndRoute();
// //   }
// //
// //   Future<void> _initLocationAndRoute() async {
// //     _userLocation = await _getUserLocation();
// //     _storeLocations = await _getStoresFromGroceryList(widget.listId);
// //     await _generateRoute();
// //     setState(() {});
// //   }
// //
// //   Future<LatLng> _getUserLocation() async {
// //     final pos = await Geolocator.getCurrentPosition();
// //     return LatLng(pos.latitude, pos.longitude);
// //   }
// //
// //   Future<List<LatLng>> _getStoresFromGroceryList(String listId) async {
// //     // Replace this with Firestore logic to determine store locations (e.g. via store name)
// //     return [
// //       LatLng(46.7712, 23.6236), // Cluj Kaufland
// //       LatLng(46.7680, 23.5899), // Cluj Lidl
// //     ];
// //   }
// //
// //   Future<void> _generateRoute() async {
// //     // This should use Google Directions API or OSRM to find the optimized route between all points
// //     // Here we just connect points in order
// //     List<LatLng> route = [_userLocation!, ..._storeLocations];
// //     final polyline = Polyline(
// //       polylineId: const PolylineId("route"),
// //       color: Colors.blue,
// //       width: 5,
// //       points: route,
// //     );
// //     _polylines = {polyline};
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (_userLocation == null)
// //       return const Center(child: CircularProgressIndicator());
// //
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Store Route")),
// //       body: GoogleMap(
// //         initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 13),
// //         myLocationEnabled: true,
// //         polylines: _polylines,
// //         markers: {
// //           Marker(markerId: const MarkerId("user"), position: _userLocation!),
// //           for (int i = 0; i < _storeLocations.length; i++)
// //             Marker(markerId: MarkerId("store$i"), position: _storeLocations[i]),
// //         },
// //         onMapCreated: (controller) => _mapController = controller,
// //       ),
// //     );
// //   }
// // }
