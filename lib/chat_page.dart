import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late final AnimationController controller;
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  final player = AudioPlayer();
  final ValueNotifier<List<Map<String, dynamic>>> savemessages =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inbox")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(widget.currentUserA + widget.currentUserB)
                .orderBy('dateTime', descending: true)
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
                  savemessages.value =
                      querySnaps.data!.docs.map((e) => e.data()).toList();
                  return ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: savemessages,
                    builder: (context, state, widget) {
                      return Expanded(
                        child: ListView.builder(
                          reverse: true,
                          itemCount: state.length,
                          itemBuilder: (_, index) {
                            return Row(
                              mainAxisAlignment:
                                  FirebaseAuth.instance.currentUser!.email ==
                                          state[index]['sender']
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: state[index]['messageType'] != "voice"
                                      ? Container(
                                          margin: const EdgeInsets.all(4),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: FirebaseAuth.instance
                                                          .currentUser!.email ==
                                                      state[index]['sender']
                                                  ? Colors.black12
                                                  : Colors.indigo,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(
                                            "${state[index]['message']}",
                                            style: TextStyle(
                                              color: FirebaseAuth.instance
                                                          .currentUser!.email ==
                                                      state[index]['sender']
                                                  ? Colors.indigo
                                                  : Colors.white,
                                            ),
                                          ))
                                      : PlayIconButton(
                                          data: state[index]['message'],
                                          containerColor: FirebaseAuth.instance
                                                      .currentUser!.email ==
                                                  state[index]['sender']
                                              ? Colors.black12
                                              : Colors.indigo,
                                          iconColor: FirebaseAuth.instance
                                                      .currentUser!.email ==
                                                  state[index]['sender']
                                              ? Colors.indigo
                                              : Colors.white,
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                default:
                  return const Center(
                    child: Text("Something went"),
                  );
              }
            },
          ),
          SendMessagesBox(
            a: widget.currentUserA,
            b: widget.currentUserB,
          ),
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
  final ValueNotifier<bool> hasFocus = ValueNotifier<bool>(false);
  final _storage = FirebaseStorage.instance;
  late final FocusNode _focusNode = FocusNode();
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
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        hasFocus.value = true;
        log("io : ${_focusNode.hasFocus}");
      } else {
        log("io : ${_focusNode.hasFocus}");
        hasFocus.value = false;
      }
    });
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
    String value = '';
    return ValueListenableBuilder(
      valueListenable: _isRecordingStart,
      builder: (_, bool newState, child) {
        switch (newState) {
          case false:
            return ValueListenableBuilder<bool>(
                valueListenable: hasFocus,
                builder: (context, focus, widget) {
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: TextField(
                            focusNode: _focusNode,
                            controller: _message,
                            onChanged: (newvalue) {
                              value = newvalue;
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          child: focus
                              ? const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.keyboard_voice_rounded,
                                  color: Colors.white,
                                ),
                        ),
                        onTap: focus
                            ? () async {
                                _message.clear();
                                await sendText(value);
                              }
                            : () async {
                                _isRecordingStart.value = true;
                                await recordingStart();
                              },
                      ),
                    ],
                  );
                });
          case true:
          default:
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _message,
                    readOnly: true,
                  ),
                ),
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_voice_rounded,
                      color: Colors.white,
                    ),
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
          "sender": FirebaseAuth.instance.currentUser!.email,
        })
        .then((value) => log("success"))
        .onError((error, stackTrace) => log("error"));
  }

  Future<void> sendText(String text) async {
    try {
      await FirebaseFirestore.instance
          .collection(widget.a + widget.b)
          .add({
            "dateTime": DateTime.now(),
            "message": text,
            "messageType": "text",
            "sender": FirebaseAuth.instance.currentUser!.email,
          })
          .then((value) => log("success"))
          .onError((error, stackTrace) => log("error"));
    } catch (e) {
      log("error $e");
    }
  }
}

class PlayIconButton extends StatefulWidget {
  final String data;
  final Color containerColor;
  final Color iconColor;
  const PlayIconButton(
      {Key? key,
      required this.data,
      required this.containerColor,
      required this.iconColor})
      : super(key: key);

  @override
  PlayIconButtonState createState() => PlayIconButtonState();
}

class PlayIconButtonState extends State<PlayIconButton>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final AudioPlayer player;

  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = widget.iconColor;
    Color containerColor = widget.containerColor;
    return ValueListenableBuilder<bool>(
      valueListenable: isPlaying,
      builder: (context, state, widget) {
        return TextButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            fixedSize: const Size(20, 20),
            shape: const CircleBorder(),
            primary: containerColor,
            onPrimary: containerColor,
          ),
          onPressed: state
              ? () async {
                  controller.reverse();
                  await player.stop();
                }
              : () async {
                  controller.forward();
                  isPlaying.value = true;
                  await playvoice();
                  await player.play();
                  await player.stop();
                  controller.reverse();
                  isPlaying.value = false;
                },
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: controller,
            color: iconColor,
          ),
        );
      },
    );
  }

  Future<void> playvoice() async {
    await player.setUrl(widget.data);
  }
}
