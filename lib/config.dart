import 'package:flutter/foundation.dart' show kIsWeb;

// ⚠️ IMPORTANT: Replace this with your computer's actual IPv4 address.
const String _yourComputerIp = '10.24.0.94';

// This variable will be 'localhost' for web and your IP for mobile.
// For your Node.js server (API, user auth, WebSockets)
const String nodeServerIp = kIsWeb ? 'localhost' : _yourComputerIp;

// For your OSRM routing server (the map routing)
const String osrmServerIp = kIsWeb ? 'localhost' : _yourComputerIp;
