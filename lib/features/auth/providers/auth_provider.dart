import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;
  firebase_auth.PhoneAuthCredential? _verifiedPhoneCredential;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _currentUser?.role;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuthListener();
    _setPersistence();
  }

  Future<void> _setPersistence() async {
    try {
      // Set Firebase Auth persistence to LOCAL to maintain session
      await _firebaseAuth.setPersistence(firebase_auth.Persistence.LOCAL);
      print('DEBUG: Firebase Auth persistence set to LOCAL');
    } catch (e) {
      print('DEBUG: Error setting persistence: $e');
    }
  }

  void _initAuthListener() {
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      print('DEBUG: Auth state changed - User: ${firebaseUser?.uid}, Initialized: $_isInitialized');
      
      // Check if user was actively using camera - if so, don't logout
      final cameraActive = await StorageService.getData('camera_active');
      if (cameraActive == 'true') {
        final timestampStr = await StorageService.getData('camera_timestamp');
        if (timestampStr != null) {
          final timestamp = int.tryParse(timestampStr) ?? 0;
          final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (elapsed < 300000) { // 5 minutes
            print('DEBUG: Camera is active, preserving session (${elapsed}ms ago)');
            if (firebaseUser == null) {
              // Restore user from storage instead of logging out
              await _loadStoredUser();
              return;
            }
          } else {
            print('DEBUG: Camera timestamp expired, clearing flag');
            await StorageService.removeData('camera_active');
            await StorageService.removeData('camera_timestamp');
          }
        }
      }
      
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser.uid);
      } else {
        // Only logout if we've already initialized (prevents logout on app resume)
        if (_isInitialized) {
          print('DEBUG: Auth state null after initialization - logging out');
          _currentUser = null;
          _isAuthenticated = false;
          notifyListeners();
        } else {
          print('DEBUG: Auth state null during initialization - checking stored user');
          // Try to load from stored data
          await _loadStoredUser();
        }
      }
      
      if (!_isInitialized) {
        _isInitialized = true;
      }
    });
  }

  Future<void> _loadStoredUser() async {
    try {
      final userData = await StorageService.getUserData('currentUser');
      if (userData != null) {
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        print('DEBUG: Loaded user from storage: ${_currentUser?.id}');
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG: Error loading stored user: $e');
    }
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromJson({...doc.data()!, 'id': uid});
        _isAuthenticated = true;
        await StorageService.saveUserData('currentUser', _currentUser!.toJson());
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? loginId,
    String? state,
  }) async {
    try {
      _errorMessage = null;
      print('Starting signup process for: $email');
      
      // Create user in Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        _errorMessage = 'Failed to create user account';
        print('Error: User credential is null');
        notifyListeners();
        return false;
      }

      print('Firebase Auth account created: ${credential.user!.uid}');

      // Link phone credential if it was verified during signup
      if (_verifiedPhoneCredential != null) {
        try {
          await credential.user!.linkWithCredential(_verifiedPhoneCredential!);
          print('Phone credential linked to account');
          _verifiedPhoneCredential = null; // Clear after use
        } catch (linkError) {
          print('Phone linking error (non-critical): $linkError');
          // Continue even if phone linking fails - the user can still use email/password
        }
      }

      // Create user document in Firestore (without 'id' field)
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
        'profileImage': null,
        'metadata': {
          if (loginId != null) 'loginId': loginId,
          if (state != null) 'state': state,
        },
      };

      try {
        await _firestore.collection('users').doc(credential.user!.uid).set(userData);
        print('User data saved to Firestore');
      } catch (firestoreError) {
        print('Firestore write error: $firestoreError');
        // Even if Firestore fails, we can continue with local storage
        // The user is already created in Firebase Auth
      }

      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _isAuthenticated = true;
      await StorageService.saveUserData('currentUser', user.toJson());
      
      print('Signup completed successfully');
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      print('Firebase Auth error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      print('Signup error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, [UserRole? role]) async {
    try {
      _errorMessage = null;
      print('Starting login process for: $email');
      
      // Sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        _errorMessage = 'Login failed';
        print('Error: User credential is null');
        notifyListeners();
        return false;
      }

      print('Firebase Auth login successful: ${credential.user!.uid}');

      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      
      if (!doc.exists) {
        print('Warning: User document not found in Firestore. Creating one...');
        
        // If user data doesn't exist in Firestore (e.g., signed up from web without proper setup)
        // Create a basic user document
        final basicUserData = {
          'name': credential.user!.displayName ?? email.split('@')[0],
          'email': email,
          'phone': credential.user!.phoneNumber ?? '',
          'role': role?.toString().split('.').last ?? 'consumer',
          'createdAt': DateTime.now().toIso8601String(),
          'profileImage': credential.user!.photoURL,
          'metadata': {'migratedFromAuth': true},
        };
        
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set(basicUserData);
          print('User document created successfully');
          
          // Use the newly created data
          final userRole = role ?? UserRole.consumer;
          _currentUser = User(
            id: credential.user!.uid,
            name: basicUserData['name'] as String,
            email: email,
            phone: basicUserData['phone'] as String,
            role: userRole,
            createdAt: DateTime.now(),
            profileImage: basicUserData['profileImage'] as String?,
          );
        } catch (firestoreError) {
          print('Failed to create user document: $firestoreError');
          // Continue with minimal user data
          _currentUser = User(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? email.split('@')[0],
            email: email,
            phone: '',
            role: role ?? UserRole.consumer,
            createdAt: DateTime.now(),
          );
        }
      } else {
        // User document exists in Firestore
        final userData = doc.data()!;
        print('User data retrieved from Firestore: ${userData['role']}');
        
        final userRole = UserRole.values.firstWhere(
          (r) => r.toString().split('.').last == userData['role'],
          orElse: () => UserRole.consumer,
        );

        // If role is provided, verify it matches
        if (role != null && userRole != role) {
          _errorMessage = 'Invalid role. Please select the correct role.';
          print('Error: Role mismatch - expected $role, got $userRole');
          await _firebaseAuth.signOut();
          notifyListeners();
          return false;
        }

        _currentUser = User.fromJson({...userData, 'id': credential.user!.uid});
      }

      _isAuthenticated = true;

      // Save to storage
      await StorageService.saveUserData('currentUser', _currentUser!.toJson());
      await StorageService.saveUserData('authToken', await credential.user!.getIdToken());

      print('Login completed successfully');
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      print('Firebase Auth error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      print('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _isAuthenticated = false;

      await StorageService.saveUserData('currentUser', null);
      await StorageService.saveUserData('authToken', null);

      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    try {
      // Update in Firestore
      await _firestore.collection('users').doc(_currentUser!.id).update(updates);

      // Create updated user
      final updatedUser = User(
        id: _currentUser!.id,
        name: updates['name'] ?? _currentUser!.name,
        email: updates['email'] ?? _currentUser!.email,
        phone: updates['phone'] ?? _currentUser!.phone,
        role: _currentUser!.role,
        profileImage: updates['profileImage'] ?? _currentUser!.profileImage,
        createdAt: _currentUser!.createdAt,
        metadata: updates['metadata'] ?? _currentUser!.metadata,
      );

      _currentUser = updatedUser;
      await StorageService.saveUserData('currentUser', _currentUser!.toJson());

      notifyListeners();
    } catch (e) {
      print('Update profile error: $e');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'An error occurred. Please try again';
    }
  }

  // Phone Authentication Methods
  
  /// Send OTP to phone number for login
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _errorMessage = null;
      print('Sending OTP to: $phoneNumber');
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          print('Auto verification completed');
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          _errorMessage = _getPhoneErrorMessage(e.code);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send OTP: ${e.toString()}';
      print('Send OTP error: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Verify OTP and sign in
  Future<bool> verifyOTP(String otp, {UserRole? role}) async {
    try {
      if (_verificationId == null) {
        _errorMessage = 'Please request OTP first';
        notifyListeners();
        return false;
      }
      
      _errorMessage = null;
      print('Verifying OTP: $otp');
      
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      return await _signInWithPhoneCredential(credential, role: role);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getPhoneErrorMessage(e.code);
      print('Verify OTP error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to verify OTP: ${e.toString()}';
      print('Verify OTP error: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Verify OTP for signup (doesn't sign in, just validates the OTP)
  Future<bool> verifyOTPForSignup(String otp) async {
    try {
      if (_verificationId == null) {
        _errorMessage = 'Please request OTP first';
        notifyListeners();
        return false;
      }
      
      _errorMessage = null;
      print('Verifying OTP for signup: $otp');
      
      // Create credential but don't sign in yet
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // Store the credential for later use during signup
      _verifiedPhoneCredential = credential;
      
      print('OTP verified successfully, credential stored');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getPhoneErrorMessage(e.code);
      print('Verify OTP error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to verify OTP: ${e.toString()}';
      print('Verify OTP error: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Sign up with phone number and OTP
  Future<bool> signUpWithPhone({
    required String phoneNumber,
    required String otp,
    required String name,
    required UserRole role,
    String? loginId,
    String? state,
  }) async {
    try {
      if (_verificationId == null) {
        _errorMessage = 'Please request OTP first';
        notifyListeners();
        return false;
      }
      
      _errorMessage = null;
      print('Signing up with phone: $phoneNumber');
      
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        _errorMessage = 'Failed to create user account';
        notifyListeners();
        return false;
      }
      
      print('Phone auth successful: ${userCredential.user!.uid}');
      
      // Create user document in Firestore
      final userData = {
        'name': name,
        'email': '', // Phone auth doesn't have email
        'phone': phoneNumber,
        'role': role.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
        'profileImage': null,
        'metadata': {
          'authMethod': 'phone',
          if (loginId != null) 'loginId': loginId,
          if (state != null) 'state': state,
        },
      };
      
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        print('User data saved to Firestore');
      } catch (firestoreError) {
        print('Firestore write error: $firestoreError');
      }
      
      final user = User(
        id: userCredential.user!.uid,
        name: name,
        email: '',
        phone: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
      );
      
      _currentUser = user;
      _isAuthenticated = true;
      await StorageService.saveUserData('currentUser', user.toJson());
      
      print('Signup with phone completed successfully');
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getPhoneErrorMessage(e.code);
      print('Signup with phone error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      print('Signup with phone error: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> _signInWithPhoneCredential(
    firebase_auth.PhoneAuthCredential credential,
    {UserRole? role}
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        _errorMessage = 'Login failed';
        notifyListeners();
        return false;
      }
      
      print('Phone auth successful: ${userCredential.user!.uid}');
      
      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!doc.exists) {
        _errorMessage = 'User not found. Please sign up first.';
        // Delete the Firebase Auth user since they haven't completed signup
        try {
          await userCredential.user!.delete();
          print('Deleted orphaned Firebase Auth user');
        } catch (deleteError) {
          print('Error deleting auth user: $deleteError');
          await _firebaseAuth.signOut();
        }
        notifyListeners();
        return false;
      }
      
      final userData = doc.data()!;
      final userRole = UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == userData['role'],
        orElse: () => UserRole.consumer,
      );
      
      // If role is provided, verify it matches
      if (role != null && userRole != role) {
        _errorMessage = 'Invalid role. Please select the correct role.';
        // Delete the Firebase Auth user on role mismatch
        try {
          await userCredential.user!.delete();
          print('Deleted Firebase Auth user due to role mismatch');
        } catch (deleteError) {
          print('Error deleting auth user: $deleteError');
          await _firebaseAuth.signOut();
        }
        notifyListeners();
        return false;
      }
      
      _currentUser = User.fromJson({...userData, 'id': userCredential.user!.uid});
      _isAuthenticated = true;
      
      await StorageService.saveUserData('currentUser', _currentUser!.toJson());
      await StorageService.saveUserData('authToken', await userCredential.user!.getIdToken());
      
      print('Phone login completed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      print('Phone sign in error: $e');
      notifyListeners();
      return false;
    }
  }
  
  String _getPhoneErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP expired. Please request a new one';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'missing-phone-number':
        return 'Please provide a phone number';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'An error occurred. Please try again';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
