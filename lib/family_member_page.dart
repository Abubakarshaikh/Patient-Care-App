import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FamilyMemberPage extends StatelessWidget {
  static route() {
    return MaterialPageRoute(builder: (_) => const FamilyMemberPage());
  }

  const FamilyMemberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family member"),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('userconnection')
              .where('usernameA', isEqualTo: currentUser!.email ?? '')
              .get(),
          builder: (context, snaps1) {
            switch (snaps1.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const Center(
                  child: CircularProgressIndicator(),
                );
              case ConnectionState.active:
              case ConnectionState.done:
                final userB = snaps1.data!.docs.map((e) => e.data()).toList()[0]
                    ['usernameB'];
                return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('familymembers')
                        .where(
                          'patientEmail',
                          isEqualTo: userB,
                        )
                        .get(),
                    builder: (context, snaps2) {
                      switch (snaps2.connectionState) {
                        case ConnectionState.none:
                        case ConnectionState.waiting:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final member =
                              snaps2.data!.docs.map((e) => e.data()).toList();
                          return SingleChildScrollView(
                            padding: EdgeInsets.all(16.0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                children: member.map((member) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['email'],
                                        style: TextStyle(height: 1.5),
                                        textAlign: TextAlign.left,
                                      ),
                                      Text(
                                        member['name'],
                                        textAlign: TextAlign.left,
                                        style: TextStyle(height: 1.5),
                                      ),
                                      Text(
                                        member['number'],
                                        style: TextStyle(height: 1.5),
                                      ),
                                      Text(
                                        member['patientEmail'],
                                        textAlign: TextAlign.left,
                                        style: TextStyle(height: 1.5),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        default:
                          return const Center(
                            child: Text("Something went wrong"),
                          );
                      }
                    });
              default:
                return const Center(
                  child: Text("Something went wrong"),
                );
            }
          }),
    );
  }
}
