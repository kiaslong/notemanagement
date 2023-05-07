import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrashBinScreen extends StatefulWidget {
  @override
  _TrashBinScreenState createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen> {
  late CollectionReference<Map<String, dynamic>> _trashBinCollection;
  final user = FirebaseAuth.instance.currentUser!;
  @override
  void initState() {
    super.initState();
    _trashBinCollection = FirebaseFirestore.instance
        .collection(user.uid)
        .doc('bin')
        .collection('notes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showConfirmationDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _trashBinCollection.snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasData) {
            final notes = snapshot.data!.docs;

            if (notes.isEmpty) {
              return const Center(
                child: Text('Trash bin is empty'),
              );
            }

            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (BuildContext context, int index) {
                final note = notes[index].data();
                final noteId = notes[index].id;

                return ListTile(
                  title: Text(note['title']),
                  subtitle: Text(note['content']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        onPressed: () {
                          restoreNoteFromTrashBin(noteId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteSingleNoteFromTrashBin(noteId);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void deleteSingleNoteFromTrashBin(String noteId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to permanently delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                try {
                  // Get a reference to the note document in the trash bin collection
                  DocumentReference noteRef = FirebaseFirestore.instance
                      .collection(user.uid)
                      .doc('bin')
                      .collection('notes')
                      .doc(noteId);

                  // Delete the note from the trash bin collection
                  await noteRef.delete();

                  // Display a success message or perform any additional actions
                } catch (error) {
                  // Handle any errors that occur during the delete process
                }
              },
            ),
          ],
        );
      },
    );
  }

  void restoreNoteFromTrashBin(String noteId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text('Are you sure you want to restore this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Restore'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                try {
                  // Get a reference to the note document in the trash bin collection
                  DocumentReference noteRef = FirebaseFirestore.instance
                      .collection(user.uid)
                      .doc('bin')
                      .collection('notes')
                      .doc(noteId);

                  // Get the note data before restoring it
                  DocumentSnapshot noteSnapshot = await noteRef.get();
                  Map<String, dynamic>? noteData =
                      noteSnapshot.data() as Map<String, dynamic>?;

                  // Move the note back to the user's collection
                  await FirebaseFirestore.instance
                      .collection(user.uid)
                      .doc(noteId)
                      .set(noteData!);

                  // Delete the note from the trash bin collection
                  await noteRef.delete();

                  // Display a success message or perform any additional actions
                } catch (error) {
                  // Handle any errors that occur during the restore process
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Permanent Delete'),
          content: const Text(
              'Are you sure you want to permanently delete all notes?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete All'),
              onPressed: () {
                deleteAllNotesFromTrashBin(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteAllNotesFromTrashBin(BuildContext context) async {
    // Fetch all notes from the trash bin collection
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _trashBinCollection.get();

    // Delete each note individually
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Show a success dialog
  }
}
