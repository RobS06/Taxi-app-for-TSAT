import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class UserProfile {
  final String name;
  final String email;
  final String phoneNumber;
  UserProfile(
      {required this.name, required this.email, required this.phoneNumber});
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
        name: json['name'] ?? 'N/A',
        email: json['email'] ?? 'N/A',
        phoneNumber: json['phone_number'] ?? 'N/A');
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<UserProfile> _profileFuture;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // UPDATED: Using nodeServerIp
    final url = Uri.parse('http://$nodeServerIp:3000/api/user/profile');
    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return UserProfile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user profile.');
    }
  }

  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in both password fields.')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      // UPDATED: Using nodeServerIp
      final url =
          Uri.parse('http://$nodeServerIp:3000/api/user/update-password');
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: json.encode({
            'oldPassword': _oldPasswordController.text,
            'newPassword': _newPasswordController.text
          }));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.green));
        _oldPasswordController.clear();
        _newPasswordController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load profile.'));
          }
          final profile = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileInfo('Name', profile.name),
                _buildProfileInfo('Email', profile.email),
                _buildProfileInfo('Phone Number', profile.phoneNumber),
                const Divider(height: 50, thickness: 1),
                const Text('Change Password',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Old Password')),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New Password')),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _updatePassword,
                        child: const Text('Update Password'))
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ]),
    );
  }
}
