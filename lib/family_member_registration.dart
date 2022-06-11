import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/login_page.dart';

class FamilyMemberRegistration extends StatefulWidget {
  static Route<FamilyMemberRegistration> route() {
    return MaterialPageRoute(builder: (_) => const FamilyMemberRegistration());
  }

  const FamilyMemberRegistration({Key? key}) : super(key: key);

  @override
  State<FamilyMemberRegistration> createState() =>
      _FamilyMemberRegistrationState();
}

class _FamilyMemberRegistrationState extends State<FamilyMemberRegistration> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _patientEmail;

  @override
  void initState() {
    _name = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _patientEmail = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _patientEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family Registration")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                hintText: 'fullname',
                helperText: 'e.g. abubakar shaikh',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.emailAddress,
              controller: _email,
              decoration: const InputDecoration(
                hintText: 'email',
                helperText: 'e.g john@gmail.com',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              controller: _phone,
              decoration: const InputDecoration(
                  hintText: 'phone number', helperText: 'e.g +921310-3896331'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.emailAddress,
              controller: _patientEmail,
              decoration: const InputDecoration(
                  hintText: 'patient email', helperText: 'e.g john@gmail.com'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await save();
              },
              child: const Text("submit"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    try {
      await FirebaseFirestore.instance.collection('familymembers').add({
        "name": _name.text,
        "email": _email.text,
        "number": _phone.text,
        "patientEmail": _patientEmail.text,
      });
      showGenericDialog();
    } catch (e) {
      log("Error: $e");
    }
  }

  showGenericDialog() {
    return showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Family Registration'),
            content: const Text('You have been Registered!'),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(context, LoginPage.route);
                },
                child: const Text("back to home"),
              ),
            ],
          );
        });
  }
}
