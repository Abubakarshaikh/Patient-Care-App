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
  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
              return Column(
                children: [
                  SwitcherButtons(usernameA: snaps.data!.first['usernameA']),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snaps.data!.length,
                      itemBuilder: (_, index) {
                        return InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("${snaps.data![index]['usernameA']}"),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  return ChatPage(
                                    currentUserA: snaps.data![index]
                                        ['usernameB'],
                                    currentUserB: snaps.data![index]
                                        ['usernameA'],
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
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
}

class SwitcherButtons extends StatelessWidget {
  final String usernameA;
  SwitcherButtons({Key? key, required this.usernameA}) : super(key: key);

  final ValueNotifier<bool?> isMorning = ValueNotifier(null);
  final ValueNotifier<bool?> isDay = ValueNotifier(null);
  final ValueNotifier<bool?> isNight = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    log("${usernameA}");
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appusers')
            .where('username', isEqualTo: usernameA)
            .snapshots(),
        builder: (context, snaps) {
          switch (snaps.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.done:
            case ConnectionState.active:
              log("---${snaps.hasData}---");
              final appsuser = snaps.data!.docs.map((e) {
                return e;
              }).toList()[0];
              final ref = appsuser.reference;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text("Morning Medicine"),
                        Switch(
                          value: appsuser.data()['morningMedicine'],
                          onChanged: (newvalue) {
                            ref.update({
                              "username": appsuser.data()['username'],
                              "password": appsuser.data()['password'],
                              "latitude": appsuser.data()['latitude'],
                              "longitude": appsuser.data()['longitude'],
                              "userType": appsuser.data()['userType'],
                              "currentDateTime":
                                  appsuser.data()['currentDateTime'],
                              "assignedPatient": 0,
                              "morningMedicine": newvalue,
                              "dayMedicine": appsuser.data()['dayMedicine'],
                              "nightMedicine": appsuser.data()['nightMedicine'],
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Day Medicine"),
                        Switch(
                          value: appsuser.data()['dayMedicine'],
                          onChanged: (newvalue) {
                            ref.update({
                              "username": appsuser.data()['username'],
                              "password": appsuser.data()['password'],
                              "latitude": appsuser.data()['latitude'],
                              "longitude": appsuser.data()['longitude'],
                              "userType": appsuser.data()['userType'],
                              "currentDateTime":
                                  appsuser.data()['currentDateTime'],
                              "assignedPatient": 0,
                              "morningMedicine":
                                  appsuser.data()['morningMedicine'],
                              "dayMedicine": newvalue,
                              "nightMedicine": appsuser.data()['nightMedicine'],
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Night medicine"),
                        Switch(
                          value: appsuser.data()['nightMedicine'],
                          onChanged: (newvalue) {
                            ref.update({
                              "username": appsuser.data()['username'],
                              "password": appsuser.data()['password'],
                              "latitude": appsuser.data()['latitude'],
                              "longitude": appsuser.data()['longitude'],
                              "userType": appsuser.data()['userType'],
                              "currentDateTime":
                                  appsuser.data()['currentDateTime'],
                              "assignedPatient": 0,
                              "morningMedicine":
                                  appsuser.data()['morningMedicine'],
                              "dayMedicine": appsuser.data()['dayMedicine'],
                              "nightMedicine": newvalue,
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );

            default:
              return const Center(
                child: Text("Something went wrong"),
              );
          }
        });
  }
}
