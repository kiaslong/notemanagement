import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notemanagement_app/class/notes.dart';
import 'package:notemanagement_app/screens/my_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notemanagement_app/screens/note_edit_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool isSwitched = false;

  List<String> _selectedLabels = [];
  @override
  void initState() {
    super.initState();
    _selectedLabels = widget.note.labels!;
    isSwitched = widget.note.isLock;
  }

  List<String> labels = [
    'Personal',
    'Work',
    'Shopping',
    'Travel Plan',
    'Finance',
    'Home',
    'School ',
    'Food Recipe',
  ];

  void updateNoteLabels(Note note, List<String> labels) async {
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc(note.id.toString())
        .update({'labels': labels});
  }

  void updateLockState(Note note, bool isSwitch) async {
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc(note.id.toString())
        .update({'isLock': isSwitch});
  }

  Future<void> updatePasswordInFirestore(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance
          .collection(user.uid)
          .doc(widget.note.id.toString());
      await userDoc.update({'password': password, 'isLock': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted =
        DateFormat.yMMMd().add_jm().format(widget.note.selectedDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyHomePage(
                  selectedFont: widget.note.fontStyle,
                  selectedFontSize: widget.note.fontSize,
                ),
              ),
            );
          },
        ),
        title: const Text('Note Details'),
        actions: [
          Visibility(
            visible: widget.note.password != null,
            child: Switch(
              value: isSwitched,
              onChanged: (bool value) {
                // Check if the password is not empty
                setState(() {
                  isSwitched = value;
                  updateLockState(widget.note, isSwitched);
                });
              },
              activeColor: Colors.blue, // Optional: Customize the active color
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String password = '';

                  return AlertDialog(
                    title: const Text('Enter Password'),
                    content: TextField(
                      onChanged: (value) {
                        password = value;
                      },
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          // Update the password in Firestore
                          await updatePasswordInFirestore(password);

                          setState(() {
                            isSwitched = true;
                          });

                          Navigator.of(context).pop();
                        },
                        child: const Text('Add/Change Password'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: isSwitched
                ? const Icon(Icons.lock)
                : const Icon(Icons.lock_open),
          ),
          IconButton(
            onPressed: () async {
              final List<String>? result =
                  await showModalBottomSheet<List<String>>(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(builder:
                      (BuildContext context, StateSetter setModalState) {
                    return Container(
                      height: 400,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: labels.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  title: Text(labels[index]),
                                  value:
                                      _selectedLabels.contains(labels[index]),
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        _selectedLabels.add(labels[index]);
                                      } else {
                                        _selectedLabels.remove(labels[index]);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextButton(
                              child: const Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop(_selectedLabels);
                                updateNoteLabels(widget.note, _selectedLabels);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
              if (result != null) {
                setState(() {
                  _selectedLabels = result;
                });
              }
            },
            icon: const Icon(Icons.label),
          ),
          IconButton(
            onPressed: () {
              // Navigate to AddNoteScreen and pass initial values

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateNoteScreen(note: widget.note),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remind date: $dateFormatted',
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                    fontFamily: widget.note.fontStyle),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Title: ${widget.note.title}',
                style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: widget.note.fontStyle),
              ),
              const SizedBox(height: 40.0),
              Row(
                children: [
                  Text(
                    'Labels:  ',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                        fontFamily: widget.note.fontStyle),
                  ),
                  if (widget.note.isPriority)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        color: Colors.amber.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'Priority',
                        style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontFamily: widget.note.fontStyle),
                      ),
                    ),
                  if (_selectedLabels.isNotEmpty)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.blue.withOpacity(0.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: [
                            for (String label in _selectedLabels)
                              Chip(
                                label: Text(label),
                                backgroundColor: Colors.blue,
                                labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40.0),
              Text(
                'Content: ${widget.note.content}',
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                    fontFamily: widget.note.fontStyle),
              ),
              const SizedBox(height: 48.0),
              if (widget.note.filesPath != null &&
                  widget.note.filesPath!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: widget.note.fontStyle),
                    ),
                    const SizedBox(height: 8.0),
                    for (final path in widget.note.filesPath!)
                      Row(
                        children: [
                          const Icon(Icons.attachment),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                if (!kIsWeb) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FilePreviewScreen(filePath: path),
                                    ),
                                  );
                                } else {
                                  launchUrlString(path);
                                }
                              },
                              child: Text(
                                Uri.decodeComponent(
                                    Uri.parse(path).pathSegments.last),
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilePreviewScreen extends StatelessWidget {
  final String filePath;

  const FilePreviewScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(
          filePath,
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Text(filePath);
          },
        ),
      ),
    );
  }
}
