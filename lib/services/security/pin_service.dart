import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  PinService([SharedPreferences? prefs]) : _prefs = prefs;

  static const String _pinHashKey = 'pin_hash';
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      return prefs;
    }
    return SharedPreferences.getInstance();
  }

  Future<bool> hasPin() async {
    final SharedPreferences prefs = await _instance();
    final String? value = prefs.getString(_pinHashKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(_pinHashKey, _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final SharedPreferences prefs = await _instance();
    final String? currentHash = prefs.getString(_pinHashKey);
    if (currentHash == null || currentHash.isEmpty) {
      return false;
    }
    return currentHash == _hashPin(pin);
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
