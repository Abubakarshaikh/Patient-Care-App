import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/chat_page.dart';
import 'package:patient_care/family_member_page.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
String? selectedNotificationPayload;
final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

class CaregiverPage extends StatefulWidget {
  static Route<CaregiverPage> route() {
    return MaterialPageRoute(builder: (_) => const CaregiverPage());
  }

  const CaregiverPage({Key? key}) : super(key: key);

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {
        debugPrint('notification payload: $payload');
      }
      selectedNotificationPayload = payload;
      selectNotificationSubject.add(payload);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Caregiver"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
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
              return ListView.builder(
                itemCount: snaps.data!.length,
                itemBuilder: (_, index) {
                  return ListTile(
                    trailing: IconButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) {
                            return ChatPage(
                              currentUserA: snaps.data![index]['usernameB'],
                              currentUserB: currentUserEmail!,
                            );
                          }));
                        },
                        icon: Icon(Icons.message, color: Colors.indigo)),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.all(4.0),
                          padding: EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Colors.indigo,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, FamilyMemberPage.route());
                            },
                            child: Text('Contact family members',
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 12.0,
                                )),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        "${snaps.data![index]['usernameB']}",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  );
                },
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
    await _pushNotification();
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

  Future<void> _pushNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentCargiver = await FirebaseFirestore.instance
        .collection('appusers')
        .where(
          'username',
          isEqualTo: currentUser!.email,
        )
        .get()
        .then((value) {
      return value.docs.map((e) {
        return e.data();
      }).toList()[0];
    });

    final morningMedicine = currentCargiver["morningMedicine"] as bool;
    final dayMedicine = currentCargiver["dayMedicine"] as bool;
    final nightMedicine = currentCargiver["nightMedicine"] as bool;

    if (!morningMedicine) {
      await _repeatNotification();
      // await _scheduleDailyTenAMNotification();
    } else {
      await _cancelNotification();
    }

    // if (dayMedicine) {
    //   await _scheduleDailyTwoPMNotification();
    // } else {
    //   await _cancelNotification();
    // }

    // if (nightMedicine) {
    //   await _scheduleDailyTweentyTwoPMNotification();
    // } else {
    //   await _cancelNotification();
    // }
  }

  Future<void> _scheduleDailyTenAMNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'daily scheduled medicine time',
        'This is time for your medicine..',
        _nextInstanceOfTenAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails('daily notification channel id',
              'daily notification channel name',
              channelDescription: 'daily notification description'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> _scheduleDailyTwoPMNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'daily scheduled notification title',
        'daily scheduled notification body',
        _nextInstanceOfTwoPM(),
        const NotificationDetails(
          android: AndroidNotificationDetails('daily notification channel id',
              'daily notification channel name',
              channelDescription: 'daily notification description'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> _scheduleDailyTweentyTwoPMNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'daily scheduled notification title',
        'daily scheduled notification body',
        _nextInstanceOfTweentyTwoPM(),
        const NotificationDetails(
          android: AndroidNotificationDetails('daily notification channel id',
              'daily notification channel name',
              channelDescription: 'daily notification description'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTwoPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 14);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTweentyTwoPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _repeatNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'repeating channel id', 'repeating channel name',
            channelDescription: 'repeating description');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
        'repeating body', RepeatInterval.everyMinute, platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }
}
