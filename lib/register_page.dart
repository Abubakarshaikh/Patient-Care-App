import 'dart:developer';
import 'family_member_registration.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:patient_care/caregiver_page.dart';
import 'package:patient_care/main.dart';
import 'package:patient_care/patient_page.dart';

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  static Route<RegisterPage> route() {
    return MaterialPageRoute(builder: (_) => RegisterPage());
  }

  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _confermpassword;

  List<Disease> diseases = [
    Disease(id: "1", name: "Heart Patient"),
    Disease(id: "2", name: "Kidney Patient"),
    Disease(id: "3", name: "Liver Patient"),
  ];

  ValueNotifier<String?> _selectedDisease = ValueNotifier<String?>(null);

  ValueNotifier<UserOption> _selectedUserOption =
      ValueNotifier<UserOption>(UserOption.caregiver);

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    _password = TextEditingController();
    _confermpassword = TextEditingController();
    _username = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _password.dispose();
    _confermpassword.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: Colors.black54),
                ),
                child: ValueListenableBuilder<UserOption>(
                    valueListenable: _selectedUserOption,
                    builder: (context, state, widget) {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Row(
                              children: [
                                Radio(
                                  value: UserOption.caregiver,
                                  groupValue: state,
                                  onChanged: (UserOption? newValue) {
                                    _selectedUserOption.value = newValue!;
                                  },
                                ),
                                const Text("Caregiver"),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Row(
                              children: [
                                Radio(
                                  value: UserOption.patient,
                                  groupValue: state,
                                  onChanged: (UserOption? newValue) {
                                    _selectedUserOption.value = newValue!;
                                  },
                                ),
                                const Text("Patient"),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _username,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'email',
                  helperText: 'A complete, valid email e.g. joe@gmail.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  hintText: 'password',
                  helperText:
                      '''Password should be at least 8 characters with at least one letter and number''',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.visiblePassword,
                controller: _confermpassword,
                decoration: const InputDecoration(
                  hintText: 'confirm password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              FutureBuilder<Position>(
                future: _determinePosition(),
                builder: (_, snaps) {
                  switch (snaps.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    case ConnectionState.active:
                    case ConnectionState.done:
                      _latitude = snaps.data!.latitude;
                      _longitude = snaps.data!.longitude;
                      return Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(16)),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Latitude"),
                                Text("${snaps.data!.latitude}")
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(16)),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Longitude"),
                                Text("${snaps.data!.longitude}"),
                              ],
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
              const SizedBox(height: 12),
              ValueListenableBuilder<UserOption>(
                valueListenable: _selectedUserOption,
                builder: (_, state, widget) {
                  return state != UserOption.caregiver
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            border: Border.all(color: Colors.black54),
                          ),
                          child: ValueListenableBuilder<String?>(
                              valueListenable: _selectedDisease,
                              builder: (context, state, widget) {
                                return DropdownButton(
                                  underline: Container(),
                                  isExpanded: true,
                                  hint: const Text("Select Disease"),
                                  value: state,
                                  items: diseases.map((disease) {
                                    return DropdownMenuItem(
                                      child: Text(disease.name),
                                      value: disease.id,
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    _selectedDisease.value = newValue!;
                                  },
                                );
                              }),
                        )
                      : const Opacity(opacity: 1);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(0, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  if (_selectedUserOption == UserOption.caregiver) {
                    try {
                      final isLoggedIn = await createUserWithEmailAndPassword(
                        email: _username.text,
                        password: _password.text,
                      );
                      await _saveCareGiverFirestore(
                        currentDateTime: DateTime.now(),
                        latitude: _latitude,
                        longitude: _longitude,
                        password: _password.text,
                        userType: "Caregiver",
                        username: _username.text,
                      );
                      if (isLoggedIn) {
                        Navigator.push(context, App.route);
                      }
                    } catch (e) {
                      log("Error: $e");
                    }
                  } else {
                    try {
                      final isLoggedIn = await createUserWithEmailAndPassword(
                        email: _username.text,
                        password: _password.text,
                      );
                      await _savePatientFirestore(
                        currentDateTime: DateTime.now(),
                        latitude: _latitude,
                        longitude: _longitude,
                        password: _password.text,
                        userType: "Patient",
                        username: _username.text,
                      );

                      if (isLoggedIn) {
                        Navigator.push(context, App.route);
                      }
                    } catch (e) {
                      log("Error: $e");
                    }
                  }
                },
                child: const Text("Register"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, LoginPage.route);
                },
                child: const Text('if registered'),
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
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final currentPosition = await Geolocator.getCurrentPosition();

    return currentPosition;
  }

  Future<void> _saveCareGiverFirestore({
    String? username,
    String? password,
    double? latitude,
    double? longitude,
    String? userType,
    DateTime? currentDateTime,
  }) async {
    final notes = FirebaseFirestore.instance.collection('appusers');
    await notes
        .add({
          "username": username,
          "password": password,
          "latitude": latitude,
          "longitude": longitude,
          "userType": userType,
          "currentDateTime": currentDateTime,
          "assignedPatient": 0,
          "morningMedicine": false,
          "dayMedicine": false,
          "nightMedicine": false
        })
        .then((value) => log('success'))
        .onError((error, stackTrace) => log("$error"));
  }

  Future<void> _savePatientFirestore({
    String? username,
    String? password,
    double? latitude,
    double? longitude,
    String? userType,
    DateTime? currentDateTime,
  }) async {
    final collect = FirebaseFirestore.instance.collection('appusers');
    List<Map<String, dynamic>> withDistanceCaregiverList = [];

    await collect.where('userType', isEqualTo: 'Caregiver').get().then(
      (QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          if (doc['assignedPatient'] <= 5) {
            Map<String, dynamic> userMap = {
              'username': doc['username'],
              'distance': Geolocator.distanceBetween(
                  latitude!, longitude!, doc['latitude'], doc['longitude'])
            };
            withDistanceCaregiverList.add(userMap);
          }
        }
      },
    );

    withDistanceCaregiverList.sort((m1, m2) {
      var r = m1["distance"].compareTo(m2["distance"]);
      if (r != 0) return r;
      return m1["distance"].compareTo(m2["distance"]);
    });

    FirebaseFirestore.instance.collection('userconnection').add({
      "usernameA": withDistanceCaregiverList[0]['username'],
      "usernameB": username,
    });

    await collect
        .add({
          "username": username,
          "password": password,
          "latitude": latitude,
          "longitude": longitude,
          "userType": userType,
          "currentDateTime": currentDateTime,
          "assignedPatient": 0,
          "morningMedicine": false,
          "dayMedicine": false,
          "nightMedicine": false
        })
        .then((value) => log('success'))
        .onError((error, stackTrace) => log("$error"));
  }

  Future<bool> createUserWithEmailAndPassword(
      {required email, required password}) async {
    final isLoggedIn = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .then((value) => value.credential);
    return isLoggedIn == null;
  }
}

class Disease {
  final String id;
  final String name;
  Disease({
    required this.id,
    required this.name,
  });
}
