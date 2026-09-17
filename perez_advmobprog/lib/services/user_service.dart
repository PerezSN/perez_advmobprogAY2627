import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

ValueNotifier<UserService> userServiceNotifier =
    ValueNotifier<UserService>(UserService());

class UserService {
  Map<String, dynamic> data = {};

  //sign in via DummyJSON, saves token and user data to SharedPrefs
  Future<Map<String, dynamic>> loginUser(
      String username, String password) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = 'dummyJson';
      await saveUserData(data);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? response.body);
    }
  }

  //create a new account via DummyJSON API.
  Future<Map<String, dynamic>> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String phone,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'phone': phone,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final newUser = jsonDecode(response.body) as Map<String, dynamic>;
      newUser['accessToken'] = '';
      newUser['refreshToken'] = '';
      newUser['loginType'] = 'dummyJson';
      await saveUserData(newUser);
      return newUser;
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? response.body);
    }
  }

  //update the stored username for a DummyJSON user.
  Future<void> updateUsernameForDummyJson(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;

    final response = await patch(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': newUsername}),
    );

    if (response.statusCode == 200) {
      await prefs.setString('username', newUsername);
    } else {
      throw Exception('Failed to update username');
    }
  }

  //delete a DummyJSON account and clear the shared preferences.
  Future<void> deleteAccountForDummyJson() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;

    final response = await delete(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      await prefs.clear();
    } else {
      throw Exception('Failed to delete account');
    }
  }

  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  fb.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  //sign in via Firebase with email + password.
  Future<fb.UserCredential> signIn(
      {required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('email', email);
    await prefs.setString(
        'username', credential.user?.displayName ?? email.split('@').first);
    await prefs.setString('firstName',
        credential.user?.displayName ?? email.split('@').first);
    await prefs.setString('lastName', '');
    await prefs.setString('image', credential.user?.photoURL ?? '');
    await prefs.setInt('id', 0);
    return credential;
  }

  //register a new user via Firebase Auth.
  Future<fb.UserCredential> signUp(
      {required String email,
      required String password,
      String displayName = ''}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('email', email);
    await prefs.setString('username', displayName.isNotEmpty ? displayName : email.split('@').first);
    await prefs.setString('firstName', displayName.isNotEmpty ? displayName : email.split('@').first);
    await prefs.setString('lastName', '');
    await prefs.setString('image', '');
    await prefs.setInt('id', 0);
    return credential;
  }

  //update the display name
  Future<void> updateUsernameForFirebase(String newDisplayName) async {
    await _firebaseAuth.currentUser?.updateDisplayName(newDisplayName);
    await _firebaseAuth.currentUser?.reload();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newDisplayName);
  }

  //change password for a Firebase user
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final credential = fb.EmailAuthProvider.credential(
        email: email, password: currentPassword);
    await _firebaseAuth.currentUser
        ?.reauthenticateWithCredential(credential);
    await _firebaseAuth.currentUser?.updatePassword(newPassword);
  }

  //delete a Firebase account
  Future<void> deleteAccountForFirebase(
      {required String email, required String password}) async {
    final credential =
        fb.EmailAuthProvider.credential(email: email, password: password);
    await _firebaseAuth.currentUser
        ?.reauthenticateWithCredential(credential);
    await _firebaseAuth.currentUser?.delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  //save user data to SharedPreferences
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);

    final loginTypeStr =
        userData['loginType'] == 'firebase' ? 'firebase' : 'dummyJson';
    await prefs.setString('loginType', loginTypeStr);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token':
          prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'loginType': prefs.getString('loginType') ?? 'dummyJson',
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('loginType') ?? 'dummyJson';
    return raw == 'firebase' ? LoginType.firebase : LoginType.dummyJson;
  }

  Future<bool> isLoggedIn() async {
    if (_firebaseAuth.currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  //clears SharedPrefs and signs out of Firebase
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}