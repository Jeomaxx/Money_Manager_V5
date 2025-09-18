import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

// User model
class User {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;
  final bool biometricEnabled;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.biometricEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
    'biometricEnabled': biometricEnabled,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    passwordHash: json['passwordHash'],
    salt: json['salt'] ?? '', // Handle migration for existing users
    createdAt: DateTime.parse(json['createdAt']),
    biometricEnabled: json['biometricEnabled'] ?? false,
  );
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _usersKey = 'app_users';
  static const String _currentUserKey = 'current_user';
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Generate secure random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(32); // 32 bytes = 256 bits
    for (int i = 0; i < saltBytes.length; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  // Hash password using PBKDF2 with salt
  String _hashPassword(String password, String salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(
      base64.decode(salt),
      100000, // 100,000 iterations
      32, // 32 bytes output length
    );
    pbkdf2.init(params);
    
    final passwordBytes = utf8.encode(password);
    final hash = pbkdf2.process(passwordBytes);
    return base64.encode(hash);
  }

  // Verify password against stored hash and salt
  bool _verifyPassword(String password, String storedHash, String salt) {
    final computedHash = _hashPassword(password, salt);
    return computedHash == storedHash;
  }

  // Generate unique user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Get all users from secure storage
  Future<List<User>> _getUsers() async {
    try {
      final usersJson = await _storage.read(key: _usersKey);
      if (usersJson == null) return [];
      
      final usersList = jsonDecode(usersJson) as List;
      return usersList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Save users to secure storage
  Future<void> _saveUsers(List<User> users) async {
    try {
      final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
      await _storage.write(key: _usersKey, value: usersJson);
    } catch (e) {
      print('Error saving users: $e');
    }
  }

  // Register new user
  Future<bool> register(String email, String password, String name) async {
    try {
      // Check if user already exists
      final users = await _getUsers();
      if (users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
        return false; // User already exists
      }

      // Create new user with secure password hashing
      final salt = _generateSalt();
      final newUser = User(
        id: _generateUserId(),
        email: email.toLowerCase().trim(),
        name: name.trim(),
        passwordHash: _hashPassword(password, salt),
        salt: salt,
        createdAt: DateTime.now(),
      );

      // Add to users list and save
      users.add(newUser);
      await _saveUsers(users);
      
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final users = await _getUsers();
      final user = users.where(
        (user) => user.email.toLowerCase() == email.toLowerCase().trim()
      ).firstOrNull;

      if (user != null) {
        bool isPasswordValid = false;
        User? updatedUser = user;

        // Check if this is a legacy user (no salt or SHA-256 format)
        if (user.salt.isEmpty || _isLegacySHA256Hash(user.passwordHash)) {
          // Verify with legacy SHA-256
          if (_verifyLegacyPassword(password, user.passwordHash)) {
            isPasswordValid = true;
            // Migrate to secure PBKDF2
            final newSalt = _generateSalt();
            updatedUser = User(
              id: user.id,
              email: user.email,
              name: user.name,
              passwordHash: _hashPassword(password, newSalt),
              salt: newSalt,
              createdAt: user.createdAt,
              biometricEnabled: user.biometricEnabled,
            );
            // Update user in storage
            final userIndex = users.indexWhere((u) => u.id == user.id);
            if (userIndex != -1) {
              users[userIndex] = updatedUser;
              await _saveUsers(users);
            }
          }
        } else {
          // Modern PBKDF2 verification
          isPasswordValid = _verifyPassword(password, user.passwordHash, user.salt);
        }

        if (isPasswordValid && updatedUser != null) {
          // Save current user session
          await _setCurrentUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Check if hash looks like legacy SHA-256 (64 hex characters)
  bool _isLegacySHA256Hash(String hash) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(hash);
  }

  // Verify password using legacy SHA-256 method
  bool _verifyLegacyPassword(String password, String storedHash) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString() == storedHash;
  }

  // Set current user session
  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  // Get current user session
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) return null;
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Check biometric availability
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Enable biometric authentication for current user
  Future<bool> enableBiometric() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      // Test biometric authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'قم بوضع إصبعك على الماسح الضوئي لتفعيل المصادقة البيومترية',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) return false;

      // Update user's biometric setting
      final users = await _getUsers();
      final userIndex = users.indexWhere((user) => user.id == currentUser.id);
      if (userIndex == -1) return false;

      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        passwordHash: currentUser.passwordHash,
        salt: currentUser.salt,
        createdAt: currentUser.createdAt,
        biometricEnabled: true,
      );

      users[userIndex] = updatedUser;
      await _saveUsers(users);
      await _setCurrentUser(updatedUser);

      return true;
    } catch (e) {
      print('Error enabling biometric: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      final users = await _getUsers();
      final userIndex = users.indexWhere((user) => user.id == currentUser.id);
      if (userIndex == -1) return false;

      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        passwordHash: currentUser.passwordHash,
        salt: currentUser.salt,
        createdAt: currentUser.createdAt,
        biometricEnabled: false,
      );

      users[userIndex] = updatedUser;
      await _saveUsers(users);
      await _setCurrentUser(updatedUser);

      return true;
    } catch (e) {
      print('Error disabling biometric: $e');
      return false;
    }
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.biometricEnabled) return false;

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'قم بوضع إصبعك على الماسح الضوئي للدخول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Check if current user has biometric enabled
  Future<bool> isBiometricEnabled() async {
    final user = await getCurrentUser();
    return user?.biometricEnabled ?? false;
  }

  // Update user profile
  Future<bool> updateProfile(String name, String email) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      // Check if email is already taken by another user
      final users = await _getUsers();
      final emailExists = users.any((user) => 
        user.email.toLowerCase() == email.toLowerCase() && user.id != currentUser.id
      );
      if (emailExists) return false;

      final userIndex = users.indexWhere((user) => user.id == currentUser.id);
      if (userIndex == -1) return false;

      final updatedUser = User(
        id: currentUser.id,
        email: email.toLowerCase().trim(),
        name: name.trim(),
        passwordHash: currentUser.passwordHash,
        salt: currentUser.salt,
        createdAt: currentUser.createdAt,
        biometricEnabled: currentUser.biometricEnabled,
      );

      users[userIndex] = updatedUser;
      await _saveUsers(users);
      await _setCurrentUser(updatedUser);

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      // Verify current password
      if (!_verifyPassword(currentPassword, currentUser.passwordHash, currentUser.salt)) {
        return false;
      }

      final users = await _getUsers();
      final userIndex = users.indexWhere((user) => user.id == currentUser.id);
      if (userIndex == -1) return false;

      // Generate new salt for password change (security best practice)
      final newSalt = _generateSalt();
      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        passwordHash: _hashPassword(newPassword, newSalt),
        salt: newSalt,
        createdAt: currentUser.createdAt,
        biometricEnabled: currentUser.biometricEnabled,
      );

      users[userIndex] = updatedUser;
      await _saveUsers(users);
      await _setCurrentUser(updatedUser);

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      final users = await _getUsers();
      users.removeWhere((user) => user.id == currentUser.id);
      await _saveUsers(users);
      await logout();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}