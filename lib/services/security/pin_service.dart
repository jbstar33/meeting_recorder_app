import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _pinHashKey = 'pin_hash';
  final FlutterSecureStorage _storage;

  Future<bool> hasPin() async {
    final String? value = await _storage.read(key: _pinHashKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final String? currentHash = await _storage.read(key: _pinHashKey);
    if (currentHash == null || currentHash.isEmpty) {
      return false;
    }
    return currentHash == _hashPin(pin);
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
