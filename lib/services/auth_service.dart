import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/tree_model.dart';
import 'database_service.dart';

class AuthService {
  static const _currentUserKey = 'geocamera_current_user';
  static final _uuid = const Uuid();

  // Securely hash passwords
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<AppUser> registerUser(String name, String email, String password, {String role = 'worker'}) async {
    final existingUser = await DatabaseService.getUserByEmail(email);
    if (existingUser != null) throw Exception('Email already registered');
    
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      email: email,
      password: _hashPassword(password),
      role: role,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await DatabaseService.insertUser(user);
    await _saveLocalSession(user);
    return user;
  }

  static Future<AppUser> loginUser(String email, String password) async {
    final user = await DatabaseService.getUserByEmail(email);
    if (user == null) throw Exception('Invalid email or password');
    if (user.password != _hashPassword(password)) throw Exception('Invalid email or password');
    
    await _saveLocalSession(user);
    return user;
  }

  static Future<void> _saveLocalSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toMap()));
  }

  static Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_currentUserKey);
    if (data == null) return null;
    return AppUser.fromMap(jsonDecode(data));
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
