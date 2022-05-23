import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/caregiver_page.dart';
import 'package:patient_care/main.dart';

import 'patient_page.dart';

class LoginPage extends StatefulWidget {
  static Route get route {
    return MaterialPageRoute(builder: (_) => LoginPage());
  }

  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    hintText: 'email',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  decoration: InputDecoration(
                    hintText: 'password',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final login = await loginAuth(
                      email: _email.text,
                      password: _password.text,
                    );
                    if (login != null) {
                      final doc = await FirebaseFirestore.instance
                          .collection('appusers')
                          .where(
                            'username',
                            isEqualTo: login.email,
                          )
                          .get()
                          .then((value) {
                        return value.docs.map((value) {
                          final newValue = value.data();
                          return newValue;
                        }).toList();
                      });

                      log("${doc.length}");

                      if (doc.any(
                          (element) => element['userType'] == 'Caregiver')) {
                        log("2");

                        Navigator.push(context, CaregiverPage.route());
                      } else {
                        log("3");
                        Navigator.push(context, PatientPage.route());
                      }
                    }
                  },
                  child: Text("Login"),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, RegisterPage.route());
                  },
                  child: Text('registred'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<User?> loginAuth({required email, required password}) async {
    final _auth = FirebaseAuth.instance;
    await _auth
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        )
        .then((value) => log('success'))
        .onError((error, stackTrace) => log('error'));
    return _auth.currentUser;
  }
}
