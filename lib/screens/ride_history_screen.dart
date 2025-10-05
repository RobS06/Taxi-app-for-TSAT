import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'review_screen.dart';

class Ride {
  final int id;
  final String pickupAddress;
  final String dropoffAddress;
  final String fare;
  final String status;
  final String createdAt;

  Ride(
      {required this.id,
      required this.pickupAddress,
      required this.dropoffAddress,
      required this.fare,
      required this.status,
      required this.createdAt});

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      fare: json['fare'].toString(),
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});
  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  late Future<List<Ride>> _rideHistoryFuture;

  @override
  void initState() {
    super.initState();
    _rideHistoryFuture = _fetchRideHistory();
  }

  Future<List<Ride>> _fetchRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Not authenticated.');

    // UPDATED: Using nodeServerIp
    final url = Uri.parse('http://$nodeServerIp:3000/api/rides/history');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    });

    if (response.statusCode == 200) {
      final List<dynamic> rideData = json.decode(response.body);
      return rideData.map((json) => Ride.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ride history.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: FutureBuilder<List<Ride>>(
        future: _rideHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no past rides.'));
          }
          final rides = snapshot.data!;
          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[900],
                child: ListTile(
                  title: Text('From: ${ride.pickupAddress}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      'To: ${ride.dropoffAddress}\nStatus: ${ride.status}',
                      style: const TextStyle(color: Colors.white70)),
                  trailing: Text('£${ride.fare}',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  onTap: () {
                    if (ride.status == 'completed') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ReviewScreen(rideId: ride.id)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('You can only review completed rides.')));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
