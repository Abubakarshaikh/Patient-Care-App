import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String currentUserA;
  final String currentUserB;
  static route() {
    return MaterialPageRoute(builder: (_) => const ChatPage());
  }

  const ChatPage({Key? key, this.currentUserA = '', this.currentUserB = ''})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inbox")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(widget.currentUserA + widget.currentUserB)
                .orderBy('dateTime', descending: false)
                .snapshots(),
            builder: (_, querySnaps) {
              switch (querySnaps.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                case ConnectionState.done:
                case ConnectionState.active:
                  return Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: querySnaps.data!.docs.length,
                      itemBuilder: (_, index) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(8)),
                                child: querySnaps.data!.docs[index]
                                            ['messageType'] !=
                                        "voice"
                                    ? Text(
                                        "${querySnaps.data!.docs.reversed.toList()[index]['message']}")
                                    : IconButton(
                                        onPressed: () async {
                                          final player = AudioPlayer();
                                          await player.setUrl(querySnaps
                                              .data!.docs[index]['message']);
                                          await player.play();
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                      ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  );
                default:
                  return const Center(
                    child: Text("Something went"),
                  );
              }
            },
          ),
          SendMessagesBox(a: widget.currentUserA, b: widget.currentUserB),
        ],
      ),
    );
  }
}

class SendMessagesBox extends StatefulWidget {
  final String a;
  final String b;
  const SendMessagesBox({
    Key? key,
    required this.a,
    required this.b,
  }) : super(key: key);

  @override
  State<SendMessagesBox> createState() => _SendMessagesBoxState();
}

class _SendMessagesBoxState extends State<SendMessagesBox> {
  final _storage = FirebaseStorage.instance;
  late final FocusNode _focusNode;
  late final ValueNotifier<bool> _isRecordingStart;
  late final TextEditingController _message;
  late final Record _record;
  late final AudioPlayer _player;
  late String fileName;
  @override
  void initState() {
    _player = AudioPlayer();
    _record = Record();
    _message = TextEditingController();
    _isRecordingStart = ValueNotifier(false);
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
    _record.dispose();
    _message.dispose();
    _isRecordingStart.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _isRecordingStart,
      builder: (_, bool newState, child) {
        switch (newState) {
          case false:
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                  ),
                ),
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: newState ? Colors.red : Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_voice_rounded,
                        color: Colors.white),
                  ),
                  onLongPress: () async {
                    _isRecordingStart.value = true;
                    await recordingStart();
                  },
                ),
              ],
            );
          case true:
          default:
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                  ),
                ),
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: newState ? Colors.red : Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_voice_rounded,
                        color: Colors.white),
                  ),
                  onTap: () async {
                    _isRecordingStart.value = false;
                    await messageSend();
                  },
                ),
              ],
            );
        }
      },
    );
  }

  Future<void> recordingStart() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String myFileName = const Uuid().v4().toString();
    log("$myFileName ------------------------");
    if (await _record.hasPermission()) {
      await _record.start(path: '${appDocDir.path}/$myFileName.mp4a');
      fileName = myFileName;
    }
  }

  Future<void> recordingStop() async {
    await _record.stop();
  }

  Future<void> messageSend() async {
    await recordingStop();

    final storageRef = FirebaseStorage.instance.ref();
    Directory appDocDir = await getApplicationDocumentsDirectory();

    String filePath = '${appDocDir.path}/$fileName.mp4a';
    File file = File(filePath);
    await storageRef
        .child(filePath.substring(filePath.lastIndexOf('/'), filePath.length))
        .putFile(file);
    final url = await storageRef.child('$fileName.mp4a').getDownloadURL();

    FirebaseFirestore.instance
        .collection(widget.a + widget.b)
        .add({
          "dateTime": DateTime.now(),
          "message": url,
          "messageType": "voice",
        })
        .then((value) => log("success"))
        .onError((error, stackTrace) => log("error"));
  }
}
