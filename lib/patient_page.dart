import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/chat_page.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({Key? key}) : super(key: key);

  static Route<PatientPage> route() {
    return MaterialPageRoute(builder: (_) => const PatientPage());
  }

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  bool _isMorning = false;
  bool _isDay = false;
  bool _isNight = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Patient"),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('appusers')
            .where('username', isEqualTo: user)
            .get(),
        builder: (_, snaps) {
          switch (snaps.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.active:
            case ConnectionState.done:
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Text("Morining"),
                        Switch(
                          value: _isMorning,
                          onChanged: (newValue) {
                            _isMorning = newValue;
                            updateFirestore();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Text("Day"),
                        Switch(
                          value: _isDay,
                          onChanged: (newValue) {
                            _isDay = newValue;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Text("Night"),
                        Switch(
                          value: _isNight,
                          onChanged: (newValue) {
                            _isNight = newValue;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: getConnectionList(),
                    builder: (_, snaps) {
                      switch (snaps.connectionState) {
                        case ConnectionState.none:
                        case ConnectionState.waiting:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        case ConnectionState.done:
                        case ConnectionState.active:
                          return Expanded(
                            child: ListView.builder(
                              itemCount: snaps.data!.length,
                              itemBuilder: (_, index) {
                                return ListTile(
                                  title: Text(
                                      "${snaps.data![index]['usernameA']}"),
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) {
                                      return ChatPage(
                                        currentUserA: snaps.data![index]
                                            ['usernameB'],
                                        currentUserB: snaps.data![index]
                                            ['usernameA'],
                                      );
                                    }));
                                  },
                                );
                              },
                            ),
                          );
                        default:
                          return const Center(
                            child: Text("Something went wrong"),
                          );
                      }
                    },
                  ),
                ],
              );
            default:
              return const Center(
                child: Text("Something went wrong"),
              );
          }
        },
      ),
    );
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<List<Map<String, dynamic>>> getConnectionList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    return await FirebaseFirestore.instance
        .collection('userconnection')
        .get()
        .then((value) {
      return value.docs
          .map((snapshot) {
            return snapshot.data();
          })
          .where((element) => element.containsValue(currentUser!.email))
          .toList();
    });
  }

  Future<void> updateFirestore() async {
    final user = FirebaseAuth.instance.currentUser!.email;
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('appusers')
        .where('username', isEqualTo: user)
        .get();
    log("--------${user!.length}");
    QueryDocumentSnapshot doc = querySnap.docs[0];
    final getData = doc.data() as Map<String, dynamic>;

    DocumentReference docRef = doc.reference;
    await docRef.update({
      "username": getData['username'],
      "password": getData['password'],
      "latitude": getData['latitude'],
      "longitude": getData['longitude'],
      "userType": getData['userType'],
      "currentDateTime": getData['currentDateTime'],
      "assignedPatient": 0,
      "morningMedicine": true,
      "dayMedicine": true,
      "nightMedicine": true
    });
  }
}
