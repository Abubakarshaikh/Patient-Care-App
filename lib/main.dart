import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:patient_care/caregiver_page.dart';
import 'package:patient_care/patient_page.dart';
import 'package:patient_care/login_page.dart';
import 'firebase_options.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

enum UserOption { caregiver, patient }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    // selectedNotificationPayload = payload;
    // selectNotificationSubject.add(payload);
  });

  runApp(const App());
}

class App extends StatelessWidget {
  static Route get route {
    return MaterialPageRoute(builder: (_) => const App());
  }

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.indigo,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(0, 45),
              primary: Colors.indigo,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            circularTrackColor: Colors.white,
            color: Colors.indigo,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              primary: Colors.indigo,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black54),
                borderRadius: BorderRadius.all(
                  Radius.circular(16),
                )),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.indigo),
                borderRadius: BorderRadius.all(
                  Radius.circular(16),
                )),
            contentPadding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
          )),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, getByStream) {
          switch (getByStream.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            case ConnectionState.active:
            case ConnectionState.done:
              return getByStream.data != null
                  ? FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection("appusers")
                          .where(
                            'username',
                            isEqualTo: getByStream.data!.email,
                          )
                          .get(),
                      builder: (context, getByFuture) {
                        switch (getByFuture.connectionState) {
                          case ConnectionState.none:
                          case ConnectionState.waiting:
                            return const Scaffold(
                              body: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final loginUser = getByFuture.data!.docs
                                .map((e) => e.data())
                                .toList();
                            return loginUser[0]['userType'] == "Patient"
                                ? const PatientPage()
                                : const CaregiverPage();
                          default:
                            return const Scaffold(
                              body: Center(child: Text("Something went wrong")),
                            );
                        }
                      },
                    )
                  : LoginPage();
            default:
              return const Scaffold(
                body: Center(child: Text("Something went wrong")),
              );
          }
        },
      ),
    );
  }
}