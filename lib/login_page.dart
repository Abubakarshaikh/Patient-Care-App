import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/family_member_registration.dart';
import 'package:patient_care/register_page.dart';

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
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.visiblePassword,
              controller: _password,
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await loginAuth(
                  email: _email.text,
                  password: _password.text,
                );
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, RegisterPage.route());
              },
              child: const Text('if not register'),
            ),
            Container(alignment: Alignment.center, child: const Text('OR')),
            TextButton(
              onPressed: () {
                Navigator.push(context, FamilyMemberRegistration.route());
              },
              child: const Text('register family member'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loginAuth({required email, required password}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .then((value) => log('success'))
          .onError((error, stackTrace) => log('error'));
    } catch (e) {
      log("Error: $e");
    }
  }
}
