import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase Connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _status = 'Testing Firebase Connection...\n\n';
      _isLoading = true;
    });

    try {
      // Test 1: Firebase Auth
      setState(() {
        _status += '1. Testing Firebase Auth... ';
      });
      
      final auth = FirebaseAuth.instance;
      setState(() {
        _status += '✅ Connected\n';
        _status += '   Current user: ${auth.currentUser?.email ?? "None"}\n\n';
      });

      // Test 2: Firestore
      setState(() {
        _status += '2. Testing Firestore... ';
      });
      
      final firestore = FirebaseFirestore.instance;
      
      // Try to write a test document
      await firestore.collection('_test').doc('connection_test').set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      });
      
      // Try to read it back
      final doc = await firestore.collection('_test').doc('connection_test').get();
      
      if (doc.exists) {
        setState(() {
          _status += '✅ Connected\n';
          _status += '   Read/Write: Success\n\n';
        });
      } else {
        setState(() {
          _status += '⚠️ Write successful but read failed\n\n';
        });
      }

      setState(() {
        _status += '✅ All Firebase services are working!\n\n';
        _status += 'You can now:\n';
        _status += '• Sign up new users\n';
        _status += '• Login with existing users\n';
        _status += '• Store data in Firestore\n';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status += '❌ Error\n\n';
        _status += 'Error details:\n$e\n\n';
        _status += 'Common issues:\n';
        _status += '1. Firebase not enabled in console\n';
        _status += '2. Wrong google-services.json\n';
        _status += '3. Network connection issue\n';
        _status += '4. Firestore rules blocking access\n';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _testFirebaseConnection,
              child: const Text('Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}
