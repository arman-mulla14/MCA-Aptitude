import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/student.dart';
import '../core/constants/app_constants.dart';
import 'data_service.dart';

enum AuthRole { none, admin, student }

class AuthService extends ChangeNotifier {
  AuthRole _role = AuthRole.none;
  Student? _currentStudent;
  String? _authError;
  bool _isInitializing = true;

  AuthRole get role => _role;
  Student? get currentStudent => _currentStudent;
  String? get authError => _authError;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _role != AuthRole.none;
  bool get isAdmin => _role == AuthRole.admin;
  bool get isStudent => _role == AuthRole.student;

  AuthService() {
    _restoreSession();
  }

  /// Restore user session from SharedPreferences on app launch / browser refresh
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('mca_auth_role');
      final savedStudentJson = prefs.getString('mca_current_student');

      if (savedRole == 'admin') {
        _role = AuthRole.admin;
        _currentStudent = null;
      } else if (savedRole == 'student' && savedStudentJson != null) {
        _role = AuthRole.student;
        final Map<String, dynamic> studentMap = jsonDecode(savedStudentJson);
        _currentStudent = Student.fromMap(studentMap, studentMap['studentId'] ?? '');
      } else {
        _role = AuthRole.none;
        _currentStudent = null;
      }
    } catch (e) {
      if (kDebugMode) print('Session restore error: $e');
      _role = AuthRole.none;
      _currentStudent = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Student Login: GRN Number as Username, Mobile Number as Password
  Future<bool> loginStudent(String grnNumber, String mobileNumber, DataService dataService) async {
    _authError = null;

    final cleanGrn = grnNumber.trim().toUpperCase();
    final cleanMobile = mobileNumber.trim().replaceAll(RegExp(r'\D'), '');

    if (cleanGrn.isEmpty || cleanMobile.isEmpty) {
      _authError = 'Please enter both GRN Number and Mobile Number.';
      notifyListeners();
      return false;
    }

    // 1. Try finding in DataService memory list
    Student? student;
    try {
      student = dataService.students.firstWhere(
        (s) => s.grnNumber.toUpperCase() == cleanGrn,
      );
    } catch (_) {
      student = null;
    }

    // 2. If not found in local memory, query Cloud Firestore collection 'students' directly!
    if (student == null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('students').doc(cleanGrn).get();
        if (doc.exists && doc.data() != null) {
          student = Student.fromMap(doc.data()!, doc.id);
          await dataService.addStudents([student]); // Cache into memory
        } else {
          // Try case-insensitive search in Firestore
          final querySnap = await FirebaseFirestore.instance.collection('students').where('grnNumber', isEqualTo: cleanGrn).get();
          if (querySnap.docs.isNotEmpty) {
            final docData = querySnap.docs.first.data();
            student = Student.fromMap(docData, querySnap.docs.first.id);
            await dataService.addStudents([student]);
          }
        }
      } catch (e) {
        if (kDebugMode) print('Firestore direct student fetch error: $e');
      }
    }

    if (student == null) {
      _authError = 'GRN Number "$cleanGrn" is not registered. Please upload Excel records in Admin Panel first.';
      notifyListeners();
      return false;
    }

    final registeredMobile = student.mobileNumber.replaceAll(RegExp(r'\D'), '');

    if (registeredMobile == cleanMobile) {
      _role = AuthRole.student;
      _currentStudent = student;
      _authError = null;
      await _saveSessionToPrefs('student', student);
      notifyListeners();
      return true;
    } else {
      _authError = 'Invalid Mobile Number for GRN $cleanGrn.';
      notifyListeners();
      return false;
    }
  }

  /// Unified Login for both Students and Admins in the same form
  Future<bool> loginUnified(String usernameOrGrn, String passwordOrMobile, DataService dataService) async {
    _authError = null;
    final u = usernameOrGrn.trim();
    final p = passwordOrMobile.trim();

    if (u.isEmpty || p.isEmpty) {
      _authError = 'Please enter GRN Number / Username and Mobile Number / Password.';
      notifyListeners();
      return false;
    }

    // Check if credentials match Admin
    final cleanUser = u.toLowerCase();
    if (cleanUser == AppConstants.defaultAdminUsername.toLowerCase() || cleanUser == 'admin') {
      if (p == AppConstants.defaultAdminPassword || p == 'admin123' || p == 'admin') {
        _role = AuthRole.admin;
        _currentStudent = null;
        _authError = null;
        await _saveSessionToPrefs('admin', null);
        notifyListeners();
        return true;
      }
    }

    // Otherwise proceed with Student Login
    return await loginStudent(u, p, dataService);
  }

  /// Admin Login Verification
  bool loginAdmin(String username, String password) {
    _authError = null;

    final cleanUser = username.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanUser == AppConstants.defaultAdminUsername || cleanUser == 'admin') {
      if (cleanPass == AppConstants.defaultAdminPassword || cleanPass == 'admin123' || cleanPass == 'admin') {
        _role = AuthRole.admin;
        _currentStudent = null;
        _authError = null;
        _saveSessionToPrefs('admin', null);
        notifyListeners();
        return true;
      }
    }

    _authError = 'Invalid Admin credentials.';
    notifyListeners();
    return false;
  }

  /// Save session role and current student to persistent local storage
  Future<void> _saveSessionToPrefs(String roleStr, Student? student) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mca_auth_role', roleStr);
      if (student != null) {
        await prefs.setString('mca_current_student', jsonEncode(student.toMap()));
      } else {
        await prefs.remove('mca_current_student');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving session: $e');
    }
  }

  /// Logout and clear saved persistent session
  Future<void> logout() async {
    _role = AuthRole.none;
    _currentStudent = null;
    _authError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mca_auth_role');
      await prefs.remove('mca_current_student');
    } catch (e) {
      if (kDebugMode) print('Error clearing session: $e');
    }
    notifyListeners();
  }
}
