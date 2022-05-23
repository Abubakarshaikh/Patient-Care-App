import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:patient_care/chat_page.dart';

class CaregiverPage extends StatefulWidget {
  static Route<CaregiverPage> route() {
    return MaterialPageRoute(builder: (_) => const CaregiverPage());
  }

  const CaregiverPage({Key? key}) : super(key: key);

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
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
                    title: Text("${snaps.data![index]['usernameB']}"),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return ChatPage(
                          currentUserA: snaps.data![index]['usernameB'],
                          currentUserB: currentUserEmail!,
                        );
                      }));
                    },
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
