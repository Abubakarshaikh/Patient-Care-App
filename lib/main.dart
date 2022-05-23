import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:patient_care/caregiver_page.dart';
import 'package:patient_care/patient_page.dart';
import 'package:patient_care/login_page.dart';
import 'firebase_options.dart';
import 'dart:async';

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
    final currentUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
        enabledBorder: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
      )),
      home: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('appusers').snapshots(),
        builder: (_, querySnaps) {
          switch (querySnaps.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.done:
            case ConnectionState.active:
              if (currentUser != null) {
                final data = querySnaps.data!.docs.map((querySnaps) {
                  return querySnaps.data();
                }).firstWhere(
                    (element) => element.containsValue(currentUser.email));

                if (data['userType'] == 'Caregiver') {
                  return const CaregiverPage();
                } else if (data['userType'] == 'Patient') {
                  return const PatientPage();
                }
              }
              return LoginPage();

            default:
              return const Center(
                child: Text("Something went wrong"),
              );
          }
        },
      ),
    );
  }
}

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

  List<Disease> diseases = [
    Disease(id: "1", name: "Heart Patient"),
    Disease(id: "2", name: "Kidney Patient"),
    Disease(id: "3", name: "Liver Patient"),
  ];

  String _selectedDisease = "1";
  UserOption? _selectedUserOption = UserOption.caregiver;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    _password = TextEditingController();
    _username = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _password.dispose();
    _username.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _username,
                  decoration: InputDecoration(labelText: 'email'),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _password,
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
                        log("${_selectedUserOption}");
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
                        log("${_selectedUserOption}");
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
                    final user = await loginAuth(
                      email: _username.text,
                      password: _password.text,
                    );
                    log("-------$user");
                    if (user != null) {
                      if (_selectedUserOption == UserOption.caregiver) {
                        await _saveCareGiverFirestore(
                          currentDateTime: DateTime.now(),
                          latitude: _latitude,
                          longitude: _longitude,
                          password: _password.text,
                          userType: "Caregiver",
                          username: _username.text,
                        );
                        Navigator.push(context, CaregiverPage.route());
                      } else {
                        await _savePatientFirestore(
                          currentDateTime: DateTime.now(),
                          latitude: _latitude,
                          longitude: _longitude,
                          password: _password.text,
                          userType: "Patient",
                          username: _username.text,
                        );
                        Navigator.push(context, PatientPage.route());
                      }
                    }

                    // else {
                    //   final user = await loginAuth(
                    //     email: _username,
                    //     password: _password,
                    //   );
                    //   if (user != null) {
                    //     // Navigator.push(context, HomePage.route());
                    //     await _savePatientFirestore(
                    //       currentDateTime: DateTime.now(),
                    //       latitude: _latitude,
                    //       longitude: _longitude,
                    //       password: _password.text,
                    //       userType: "Patient",
                    //       username: _username.text,
                    //     );
                    //     Navigator.push(context, PatientPage.route());
                    //   }
                    // }
                  },
                  child: const Text("Registered"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, LoginPage.route);
                  },
                  child: const Text('if registered'),
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
    String? userId,
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
    String? userId,
    String? username,
    String? password,
    double? latitude,
    double? longitude,
    String? userType,
    DateTime? currentDateTime,
  }) async {
    final _collect = FirebaseFirestore.instance.collection('appusers');
    List<Map<String, dynamic>> withDistanceCaregiverList = [];

    await _collect.where('userType', isEqualTo: 'Caregiver').get().then(
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

    // log("you are assigned caregiver:" +
    //     withDistanceCaregiverList[0]['username']);
    // log("current user: $username");

    FirebaseFirestore.instance.collection('userconnection').add({
      "usernameA": withDistanceCaregiverList[0]['username'],
      "usernameB": username,
    });

    await _collect
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

  Future<User?> loginAuth({required email, required password}) async {
    final auth = FirebaseAuth.instance;
    await auth
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .then((value) => log('success'))
        .onError((error, stackTrace) => log('error $error'));
    return auth.currentUser;
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
