import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';

enum UserOption { caregiver, patient }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      )),
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  List<Disease> diseases = [
    Disease(id: "1", name: "Heart Patient"),
    Disease(id: "2", name: "Kidney Patient"),
    Disease(id: "3", name: "Liver Patient"),
  ];

  String _selectedDisease = "1";
  UserOption? _selectedUserOption = UserOption.caregiver;

  String? _username;
  String? _password;
  double? _latitude;
  double? _longitude;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Align(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (newValue) {
                    _username = newValue;
                  },
                  decoration: InputDecoration(labelText: 'email'),
                ),
                SizedBox(height: 12),
                TextField(
                  onChanged: (newValue) {
                    _password = newValue;
                  },
                  decoration: InputDecoration(labelText: 'password'),
                ),
                ListTile(
                  title: Text("Caregiver"),
                  leading: Radio(
                    value: UserOption.caregiver,
                    groupValue: _selectedUserOption,
                    onChanged: (UserOption? newValue) {
                      setState(() {
                        _selectedUserOption = newValue;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text("Patient"),
                  leading: Radio(
                    value: UserOption.patient,
                    groupValue: _selectedUserOption,
                    onChanged: (UserOption? newValue) {
                      setState(() {
                        _selectedUserOption = newValue;
                      });
                    },
                  ),
                ),
                _selectedUserOption != UserOption.caregiver
                    ? DropdownButton(
                        isExpanded: true,
                        value: _selectedDisease,
                        items: diseases.map((disease) {
                          return DropdownMenuItem(
                            child: Text(disease.name),
                            value: disease.id,
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDisease = newValue!;
                          });
                        },
                      )
                    : const Opacity(opacity: 1),
                FutureBuilder<Position>(
                  future: _determinePosition(),
                  builder: (_, AsyncSnapshot<Position> snaps) {
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

                        return Text(
                            "latitude: ${snaps.data!.latitude}, longitude: ${snaps.data!.longitude}");

                      default:
                        return const Center(child: Text("Someting went wrong"));
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveCareGiverFirestore(
                      currentDateTime: DateTime.now(),
                      latitude: _latitude,
                      longitude: _longitude,
                      password: _password,
                      userType: _selectedUserOption == UserOption.caregiver
                          ? "Caregiver"
                          : "Patient",
                      username: _username,
                    );
                  },
                  child: const Text("Registered"),
                ),
              ],
            ),
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
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _saveCareGiverFirestore({
    required String? username,
    required String? password,
    required double? latitude,
    required double? longitude,
    required String? userType,
    required DateTime? currentDateTime,
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
        })
        .then((value) => log('success'))
        .onError((error, stackTrace) => log("$error"));
  }

  Future<void> _savePatientFirestore({
    required String? username,
    required String? password,
    required double? latitude,
    required double? longitude,
    required String? userType,
    required DateTime? currentDateTime,
  }) async {
    final notes = FirebaseFirestore.instance.collection('appusers');
    List<Map<String, dynamic>> withDistanceCaregiverList = [];

    notes.where('userType', isEqualTo: 'caregiver').get().then(
      (QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          if (double.parse(doc['assignedPatient'].toString()) <= 5) {
            Map<String, dynamic> userMap = {
              'userName': doc['userName'],
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

    print(withDistanceCaregiverList[0]);

    print(
        "you are assigned caregiver:" + withDistanceCaregiverList[0]['email']);

    await notes
        .add({
          "username": username,
          "password": password,
          "latitude": latitude,
          "longitude": longitude,
          "userType": userType,
          "currentDateTime": currentDateTime,
        })
        .then((value) => log('success'))
        .onError((error, stackTrace) => log("$error"));
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
