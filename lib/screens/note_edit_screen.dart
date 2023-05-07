import 'package:flutter/material.dart';
import 'package:notemanagement_app/class/notes.dart';
import 'dart:io';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:notemanagement_app/screens/note_detail_screen.dart';

class UpdateNoteScreen extends StatefulWidget {
  final Note note;

  const UpdateNoteScreen({Key? key, required this.note}) : super(key: key);

  @override
  _UpdateNoteScreenState createState() => _UpdateNoteScreenState();
}

class _UpdateNoteScreenState extends State<UpdateNoteScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  var _titleController = TextEditingController();
  var _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _selectedDate = widget.note.selectedDate;
  }

  late Map<String, Uint8List> fileBytesList = {};
  late List<String> fileNames = [];

  DateTime _selectedDate = DateTime.now();

  late List<File> _selectedFiles = [];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //pick file functions
  Future<void> _pickFiles() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) {
        return;
      }

      setState(() {
        for (PlatformFile file in result.files) {
          Uint8List? bytes = file.bytes;
          if (bytes != null) {
            fileBytesList[file.name] = bytes;
            fileNames.add(file.name);
          }
        }
      });
    } else {
      // Code to execute when running on non-web platforms
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) {
        return;
      }

      List<String> paths = result.files.map((file) => file.path ?? "").toList();

      setState(() {
        _selectedFiles = paths.map((path) => File(path)).toList();
      });
    }
  }

  Future<void> _pickDate() async {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      currentTime: _selectedDate,
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
    );
  }

  void addNoteToFirestore(Note note, List<File> selectedFiles) async {
    // Upload the file to Firebase Storage

    List<String> fileUrls = widget.note.filesPath!;
    for (File file in _selectedFiles) {
      String filePath = 'notes/${note.id}/${file.path.split('/').last}';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      String fileUrl = await taskSnapshot.ref.getDownloadURL();
      fileUrls.add(fileUrl);
    }
    // Add the note to Firestore
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc(note.id.toString())
        .set({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'filesPath': fileUrls, // Store the file URL instead of the file path
      'selectedDate': note.selectedDate,
      'isPriority': note.isPriority,
      'fontSize': note.fontSize,
      'fontStyle': note.fontStyle,
      'labels': note.labels,
      'password': '',
    });
  }

  void addNoteToFirestoreWeb(Note note, List<String> fileNames,
      Map<String, Uint8List> fileBytesList) async {
    // Upload the files to Firebase Storage

    List<String> fileUrls = widget.note.filesPath!;
    for (String name in fileNames) {
      Uint8List? bytes = fileBytesList[name];
      if (bytes == null) {
        // Skip the file if it's empty or couldn't be read
        continue;
      }
      try {
        String filePath = 'notes/${note.id}/$name';
        Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
        UploadTask uploadTask = storageRef.putData(bytes);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        fileUrls.add(downloadUrl);
      } catch (error) {
        // Handle the error appropriately (e.g. log the error message, show an error message to the user, retry the operation)
        print('Failed to upload file $name: $error');
      }
    }

    // Add the note to Firestore
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc(note.id.toString())
        .set({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'filesPath': fileUrls, // Store the file URL instead of the file path
      'selectedDate': note.selectedDate,
      'isPriority': note.isPriority,
      'fontSize': note.fontSize,
      'fontStyle': note.fontStyle,
      'labels': note.labels,
      'password': '',
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Content',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some content';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                            'Remind date: ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(_selectedDate),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _pickDate,
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),
                          overlayColor: MaterialStateProperty.all(Colors.blue),
                          textStyle: MaterialStateProperty.all(const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                          padding: MaterialStateProperty.all(
                             const  EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ),
                        child:const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickFiles,
                    child: const Text('Add More Files'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final note = Note(
                            id: widget.note.id,
                            title: _titleController.text,
                            content: _contentController.text,
                            selectedDate: _selectedDate,
                            filesPath: widget.note.filesPath,
                            labels: widget.note.labels);

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (BuildContext context) => NoteDetailScreen(
                              note: note,
                            ),
                          ),
                          (Route<dynamic> route) => false,
                        );
                        !kIsWeb
                            ? addNoteToFirestore(note, _selectedFiles)
                            : addNoteToFirestoreWeb(
                                note, fileNames, fileBytesList);
                      }
                    },
                    child: const Text('Save'),
                  ),
                  Column(
                    children: [
                      if (kIsWeb)
                        for (int i = 0; i < fileNames.length; i++)
                          Row(
                            children: [
                              FileIcon(
                                filepath: fileNames[i],
                                size: 100,
                              ),
                              Text(fileNames[i]),
                            ],
                          ),
                      if (!kIsWeb)
                        for (int i = 0; i < _selectedFiles.length; i++)
                          Row(
                            children: [
                              FileIcon(
                                filepath: _selectedFiles[i].path,
                                size: 100,
                              ),
                              Text(_selectedFiles[i].path.split('/').last),
                            ],
                          ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

class FileIcon extends StatelessWidget {
  final String filepath;
  final double size;

  const FileIcon({
    Key? key,
    required this.filepath,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final extension = filepath.split('.').last;
    final iconData = _getIconDataForExtension(extension);
    return iconData != null
        ? Icon(iconData, size: size)
        : const Icon(Icons.insert_drive_file, size: 50);
  }

  IconData? _getIconDataForExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.file_copy;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      default:
        return null;
    }
  }
}
