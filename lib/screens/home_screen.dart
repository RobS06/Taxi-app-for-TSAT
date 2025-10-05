import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../main.dart';
import '../config.dart';

import 'ride_history_screen.dart';
import 'login_screen.dart';
import 'payment_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  double? _estimatedFare;
  double _distanceInKm = 0.0;
  WebSocketChannel? _channel;
  LatLng? _driverPosition;
  String _rideStatusMessage = "Book a ride to see its status.";

  @override
  void initState() {
    super.initState();
    // Connect to the WebSocket server as soon as the screen loads. This is the fix.
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _connectToWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$nodeServerIp:3000'));
      _channel!.sink.add(json.encode({'type': 'auth', 'token': token}));
      _channel!.stream.listen((message) {
        if (!mounted) return;
        final data = json.decode(message);
        switch (data['type']) {
          case 'ride_accepted':
            notificationService.showNotification(
                'Ride Accepted!', data['message']);
            setState(() {
              _rideStatusMessage = data['message'];
            });
            break;
          case 'driver_arrived':
            notificationService.showNotification(
                'Driver Arrived!', data['message']);
            setState(() {
              _rideStatusMessage = data['message'];
            });
            break;
          case 'driver_location_update':
            setState(() {
              _driverPosition = LatLng(data['lat'], data['lon']);
              _rideStatusMessage = "Your driver is on the way.";
            });
            break;
        }
      });
    } catch (e) {
      print("WebSocket connection failed: $e");
      if (mounted) {
        setState(() {
          _rideStatusMessage = "Real-time connection failed.";
        });
      }
    }
  }

  Future<void> _findRouteFromPostcodes() async {
    FocusScope.of(context).unfocus();
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both postcodes.')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final startCoords = await _geocodePostcode(_pickupController.text);
      final endCoords = await _geocodePostcode(_dropoffController.text);
      if (startCoords != null && endCoords != null) {
        setState(() {
          _startPoint = startCoords;
          _endPoint = endCoords;
          _mapController.move(
              LatLng((startCoords.latitude + endCoords.latitude) / 2,
                  (startCoords.longitude + endCoords.longitude) / 2),
              10);
        });
        await _getRoute();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<LatLng?> _geocodePostcode(String postcode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse(
        'http://$nodeServerIp:3000/api/geocode?postcode=${Uri.encodeComponent(postcode)}');
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return LatLng(responseData['lat'], responseData['lon']);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error finding postcode: $postcode')));
      return null;
    }
  }

  Future<void> _getRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://$nodeServerIp:3000/api/route');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'coordinates': [
          [_startPoint!.longitude, _startPoint!.latitude],
          [_endPoint!.longitude, _endPoint!.latitude],
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coordinates =
          data['features'][0]['geometry']['coordinates'] as List;
      _distanceInKm =
          (data['features'][0]['properties']['summary']['distance'] / 1000.0);
      final route =
          coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
      _estimatedFare = 2.50 + (_distanceInKm * 1.50);
      setState(() {
        _routePoints = route;
      });
      if (mounted) _showBookingSheet();
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Failed to get route: ${errorData['message']}');
    }
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Confirm Your Ride',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Text('Estimated Fare: £${_estimatedFare?.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 20, color: Colors.white)),
                  Text('Distance: ${_distanceInKm.toStringAsFixed(2)} km',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bookRide();
                      },
                      child: const Text('Book Now & Proceed to Payment'))
                ]));
      },
    );
  }

  Future<void> _bookRide() async {
    final pickupAddress = _pickupController.text.toUpperCase();
    final dropoffAddress = _dropoffController.text.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://$nodeServerIp:3000/api/rides/book');
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'pickup_address': pickupAddress,
          'dropoff_address': dropoffAddress,
          'fare': _estimatedFare
        }));

    if (!mounted) return;

    if (response.statusCode == 201) {
      // The WebSocket is already connected, so we don't need to call _connectToWebSocket() here anymore.
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const PaymentScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(json.decode(response.body)['message'] ??
              'Failed to book ride.')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      _channel?.sink.close(); // Close WebSocket on logout
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TSAT'), actions: [
        if (_isLoading)
          const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3))))
      ]),
      drawer: Drawer(
          child: Container(
              color: Colors.grey[900],
              child: ListView(padding: EdgeInsets.zero, children: [
                DrawerHeader(
                    decoration:
                        BoxDecoration(color: Theme.of(context).primaryColor),
                    child: const Center(
                        child: Text('TSAT',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)))),
                ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: const Text('User Profile',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const UserProfileScreen()));
                    }),
                ListTile(
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: const Text('Ride History',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const RideHistoryScreen()));
                    }),
                ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Log Out',
                        style: TextStyle(color: Colors.white)),
                    onTap: () => _logout()),
              ]))),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Image.asset('assets/logo.png', height: 60),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _pickupController,
                  decoration:
                      const InputDecoration(labelText: 'Pickup Postcode')),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _dropoffController,
                  decoration:
                      const InputDecoration(labelText: 'Dropoff Postcode')),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _findRouteFromPostcodes,
                      child: const Text('Find Route'))),
            ])),
        Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[900],
            width: double.infinity,
            child: Text(_rideStatusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).primaryColor))),
        Expanded(
            child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                    initialCenter: const LatLng(51.509865, -0.118092),
                    initialZoom: 13.0),
                children: [
              TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tsat.app'),
              PolylineLayer(polylines: [
                Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Theme.of(context).primaryColor)
              ]),
              MarkerLayer(markers: [
                if (_startPoint != null)
                  Marker(
                      point: _startPoint!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Colors.green, size: 40)),
                if (_endPoint != null)
                  Marker(
                      point: _endPoint!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40)),
                if (_driverPosition != null)
                  Marker(
                      point: _driverPosition!,
                      width: 80,
                      height: 80,
                      child: Icon(Icons.local_taxi,
                          color: Theme.of(context).primaryColor, size: 35)),
              ]),
            ])),
      ]),
    );
  }
}
