import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  static const _kIncidents = 'incidents';
  static const _kUsers = 'users';
  static const _kCurrentUser = 'current_user';
  static const _kOnboarded = 'onboarded';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedIfEmpty();
  }

  static SharedPreferences get prefs => _prefs!;

  // ===== USER PROFILE & AUTH =====
  static Future<bool> login(String username, String password) async {
    final users = await getUsers();
    final user = users.firstWhere(
      (u) => u['username'].toString().toLowerCase() == username.toLowerCase() && u['password'] == password,
      orElse: () => {},
    );
    if (user.isNotEmpty) {
      await prefs.setString(_kCurrentUser, json.encode(user));
      return true;
    }
    // Fallback demo login - any non-empty creates a temp user
    if (username.isNotEmpty && password.isNotEmpty) {
      final demoUser = {
        'username': username,
        'password': password,
        'name': 'Demo User',
        'designation': 'Safety Officer',
        'pno': 'BSP-001',
        'mobile': '9876543210',
        'isAdmin': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_kCurrentUser, json.encode(demoUser));
      return true;
    }
    return false;
  }

  static Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?['isAdmin'] == true;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final raw = prefs.getString(_kCurrentUser);
    if (raw == null) return null;
    return Map<String, dynamic>.from(json.decode(raw));
  }

  static Future<void> logout() async {
    await prefs.remove(_kCurrentUser);
  }

  static Future<bool> isOnboarded() async {
    return prefs.getBool(_kOnboarded) ?? false;
  }

  static Future<void> completeOnboarding(Map<String, dynamic> profile) async {
    final users = await getUsers();
    final username = profile['username'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = {
      'username': username,
      'password': profile['password'] ?? 'password',
      'name': profile['name'],
      'designation': profile['designation'],
      'pno': profile['pno'],
      'mobile': profile['mobile'],
      'isAdmin': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    users.add(newUser);
    await prefs.setStringList(_kUsers, users.map((u) => json.encode(u)).toList());
    await prefs.setString(_kCurrentUser, json.encode(newUser));
    await prefs.setBool(_kOnboarded, true);
  }

  // ===== ADMIN: USER MANAGEMENT =====
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final raw = prefs.getStringList(_kUsers) ?? [];
    return raw.map((s) => Map<String, dynamic>.from(json.decode(s))).toList();
  }

  static Future<void> addUser(Map<String, dynamic> user) async {
    final users = await getUsers();
    final newUser = Map<String, dynamic>.from(user);
    newUser['createdAt'] ??= DateTime.now().toIso8601String();
    newUser['isAdmin'] ??= false;
    users.add(newUser);
    await prefs.setStringList(_kUsers, users.map((u) => json.encode(u)).toList());
  }

  static Future<void> deleteUser(String username) async {
    final users = await getUsers();
    users.removeWhere((u) => u['username'] == username);
    await prefs.setStringList(_kUsers, users.map((u) => json.encode(u)).toList());
  }

  // ===== INCIDENTS =====
  static Future<List<Map<String, dynamic>>> getIncidents() async {
    final raw = prefs.getStringList(_kIncidents) ?? [];
    return raw.map((s) => Map<String, dynamic>.from(json.decode(s))).toList();
  }

  static Future<void> saveIncident(Map<String, dynamic> incident) async {
    final list = await getIncidents();
    final newOne = Map<String, dynamic>.from(incident);
    newOne['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();
    newOne['date'] ??= DateTime.now().toIso8601String();
    final user = await getCurrentUser();
    newOne['reportedBy'] = user?['name'] ?? 'Unknown';
    newOne['reporterPno'] = user?['pno'] ?? '';
    list.insert(0, newOne);
    await prefs.setStringList(_kIncidents, list.map((m) => json.encode(m)).toList());
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    final incidents = await getIncidents();
    final users = await getUsers();

    final byStatus = <String, int>{};
    final bySeverity = <String, int>{};
    final byLocation = <String, int>{};
    final byType = <String, int>{};

    for (final i in incidents) {
      final s = i['status']?.toString() ?? 'OPEN';
      final sev = i['severity']?.toString() ?? 'MEDIUM';
      final loc = i['location']?.toString() ?? 'Unknown';
      final type = i['type']?.toString() ?? 'OTHER';
      byStatus[s] = (byStatus[s] ?? 0) + 1;
      bySeverity[sev] = (bySeverity[sev] ?? 0) + 1;
      byLocation[loc] = (byLocation[loc] ?? 0) + 1;
      byType[type] = (byType[type] ?? 0) + 1;
    }

    return {
      'totalIncidents': incidents.length,
      'totalUsers': users.length,
      'open': byStatus['OPEN'] ?? 0,
      'closed': byStatus['CLOSED'] ?? 0,
      'investigating': byStatus['INVESTIGATING'] ?? 0,
      'critical': bySeverity['CRITICAL'] ?? 0,
      'high': bySeverity['HIGH'] ?? 0,
      'medium': bySeverity['MEDIUM'] ?? 0,
      'low': bySeverity['LOW'] ?? 0,
      'byLocation': byLocation,
      'byType': byType,
    };
  }

  static Future<void> _seedIfEmpty() async {
    // Seed admin user
    final users = await getUsers();
    if (users.isEmpty) {
      await prefs.setStringList(_kUsers, [
        json.encode({
          'username': 'admin',
          'password': 'admin',
          'name': 'System Administrator',
          'designation': 'Chief Safety Officer',
          'pno': 'SAIL-ADMIN-01',
          'mobile': '9999999999',
          'isAdmin': true,
          'createdAt': DateTime.now().toIso8601String(),
        }),
        json.encode({
          'username': 'demo',
          'password': 'demo',
          'name': 'R.K. Sharma',
          'designation': 'Sr. Safety Officer',
          'pno': 'BSP-2024-001',
          'mobile': '9876543210',
          'isAdmin': false,
          'createdAt': DateTime.now().toIso8601String(),
        }),
        json.encode({
          'username': 'priya',
          'password': 'priya',
          'name': 'Priya Singh',
          'designation': 'Safety Engineer',
          'pno': 'BSP-2024-002',
          'mobile': '9876543211',
          'isAdmin': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        }),
        json.encode({
          'username': 'rajesh',
          'password': 'rajesh',
          'name': 'Rajesh Kumar',
          'designation': 'Plant Engineer',
          'pno': 'BSP-2024-003',
          'mobile': '9876543212',
          'isAdmin': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        }),
      ]);
    }

    // Seed incidents
    if ((prefs.getStringList(_kIncidents) ?? []).isEmpty) {
      final demos = [
        {
          'id': '1',
          'title': 'PPE Violation at BF-5',
          'location': 'Blast Furnace',
          'severity': 'HIGH',
          'wsa': '3. Improper PPE',
          'desc': 'Worker without hard hat near hot metal ladle',
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'status': 'OPEN',
          'type': 'AI_SCAN',
          'reportedBy': 'R.K. Sharma',
          'reporterPno': 'BSP-2024-001',
        },
        {
          'id': '2',
          'title': 'Crane Near Miss · Rolling Mill',
          'location': 'Rolling Mill',
          'severity': 'CRITICAL',
          'wsa': '6. Communication gaps',
          'desc': 'Uncontrolled crane swing near worker',
          'date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
          'status': 'INVESTIGATING',
          'type': 'NEAR_MISS',
          'reportedBy': 'Priya Singh',
          'reporterPno': 'BSP-2024-002',
        },
        {
          'id': '3',
          'title': 'Slip Hazard · Coke Oven',
          'location': 'Coke Oven Battery',
          'severity': 'MEDIUM',
          'wsa': '8. Poor housekeeping',
          'desc': 'Water accumulation on walkway',
          'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'status': 'CLOSED',
          'type': 'NEAR_MISS',
          'reportedBy': 'Rajesh Kumar',
          'reporterPno': 'BSP-2024-003',
        },
        {
          'id': '4',
          'title': 'Hot Metal Spill (Minor)',
          'location': 'Steel Melting Shop',
          'severity': 'HIGH',
          'wsa': '1. Failure to follow procedure',
          'desc': 'Ladle alignment issue during tapping',
          'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'status': 'CLOSED',
          'type': 'AI_SCAN',
          'reportedBy': 'R.K. Sharma',
          'reporterPno': 'BSP-2024-001',
        },
      ];
      await prefs.setStringList(_kIncidents, demos.map((m) => json.encode(m)).toList());
    }
  }
}
