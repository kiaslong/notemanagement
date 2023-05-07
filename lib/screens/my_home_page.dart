import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notemanagement_app/class/notes.dart';
import 'package:notemanagement_app/screens/add_note_screen.dart';
import 'package:intl/intl.dart';
import 'package:notemanagement_app/screens/note_detail_screen.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:notemanagement_app/screens/settings_screen.dart';

class MyHomePage extends StatefulWidget {
  final String selectedFont;
  final double selectedFontSize;

  const MyHomePage({
    Key? key,
    required this.selectedFont,
    required this.selectedFontSize,

    // Initialize the parameter
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isGridView = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser!;

  String? title;

  String keyword = '';

  List<Note> notes = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotesFromFirestore();
    checkEmailVerification();
  }

  Future<void> checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
                'A verification link has been sent to your email. Please verify your email to have full access.'),
            actions: [
              TextButton(
                child: const Text('Skip verification'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  }

  List<Note> search(List<Note> notes, String keyword) {
    List<Note> results = [];
    for (Note note in notes) {
      if (note.title.toLowerCase().contains(keyword.toLowerCase()) ||
          note.content.toLowerCase().contains(keyword.toLowerCase())) {
        results.add(note);
      }
    }
    return results;
  }

  List<Note> filterByLabels(List<Note> notes, List<String> selectedLabels) {
    if (selectedLabels.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      // Check if any of the labels in note.labels intersect with the selected labels
      return note.labels!.any((label) => selectedLabels.contains(label));
    }).toList();
  }

  Future<void> _showSearchModal() async {
    final TextEditingController _searchController = TextEditingController();
    List<Note> tempNotes = notes;
    List<Note> searchResults = [];
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

    List<String> selectedLabels = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      keyword = value;
                      searchResults = search(tempNotes, keyword);
                      notes =
                          searchResults.isNotEmpty ? searchResults : tempNotes;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search for notes...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: const Text('Filter by Labels'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: labels.map((label) {
                                bool isSelected =
                                    selectedLabels.contains(label);
                                return CheckboxListTile(
                                  title: Text(label),
                                  value: isSelected,
                                  activeColor: Colors.blue,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value != null && value) {
                                        selectedLabels.add(label);
                                      } else {
                                        selectedLabels.remove(label);
                                      }

                                      searchResults = filterByLabels(
                                          tempNotes, selectedLabels);

                                      notes = searchResults.isNotEmpty
                                          ? searchResults
                                          : tempNotes;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Apply'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  notes = tempNotes;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Search'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (searchResults.isEmpty) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No results found'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

//fetch notes from Firestore
  Future<void> fetchNotesFromFirestore() async {
    setState(() {
      isLoading = true;
    });
    final notesRef = FirebaseFirestore.instance.collection(user.uid);
    final snapshot = await notesRef.get();
    final List<Note> fetchedNotes = [];
    snapshot.docs.forEach((doc) {
      final data = doc.data();
      Timestamp timestamp = doc['selectedDate'];
      double dou = data['fontSize'].toDouble();
      DateTime date = timestamp.toDate();
      final note = Note(
        id: data['id'],
        title: data['title'],
        content: data['content'],
        filesPath: List<String>.from(data['filesPath']),
        selectedDate: date,
        isPriority: data['isPriority'],
        fontSize: dou,
        fontStyle: data['fontStyle'],
        labels: List<String>.from(data['labels']),
        password: data['password'],
        isLock: data['isLock'],
      );
      fetchedNotes.add(note);
    });
    setState(() {
      notes = fetchedNotes;
      isLoading = false;
    });
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  // update priorty for notes
  void updateNotePriority(Note note, bool isPriority) async {
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc(note.id.toString())
        .update({'isPriority': isPriority});
  }

  // delete notes

  Future<void> deleteNote(Note note) async {
    // Get a reference to the note document in the user's collection
    DocumentReference noteRef =
        FirebaseFirestore.instance.collection(user.uid).doc(note.id.toString());

    // Get the note data before deleting it
    DocumentSnapshot noteSnapshot = await noteRef.get();
    Map<String, dynamic>? noteData =
        noteSnapshot.data() as Map<String, dynamic>?;

    // Move the note to the "bin" collection
    await FirebaseFirestore.instance
        .collection(user.uid)
        .doc('bin')
        .collection('notes')
        .doc(note.id.toString())
        .set(noteData!);

    // Delete the note from the user's collection
    await noteRef.delete();
  }

  Widget _buildNoteItem(BuildContext context, int index) {
    final note = notes[index];

    final notesByPriority =
        groupBy<Note, bool>(notes, (note) => note.isPriority);
    final highPriorityNotes = notesByPriority[true] ?? [];
    final normalPriorityNotes = notesByPriority[false] ?? [];

    List<Note> sectionNotes;
    Color sectionColor;
    IconData sectionIcon;

    if (note.isPriority) {
      sectionNotes = highPriorityNotes;
      sectionColor = Colors.amber;
      sectionIcon = Icons.favorite;
    } else {
      sectionNotes = normalPriorityNotes;
      sectionColor = Colors.white;
      sectionIcon = Icons.not_interested;
    }

    Widget noteSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            DateFormat('yyyy-MM-dd HH:mm').format(note.selectedDate),
            style: TextStyle(
              fontSize: note.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: _isGridView ? 1 : 0,
          child: Row(
            children: [
              if (!_isGridView)
                Text(
                  note.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: note.fontSize,
                      fontFamily: note.fontStyle),
                ),
              if (_isGridView && !kIsWeb)
                Text(
                  '${note.title.length <= 10 ? note.title : '${note.title.substring(0, 10)}...'}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: note.fontSize,
                      fontFamily: note.fontStyle),
                ),
              if (_isGridView && kIsWeb)
                Text(
                  '${note.title.length <= 25 ? note.title : '${note.title.substring(0, 25)}...'}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: note.fontSize,
                      fontFamily: note.fontStyle),
                ),
            ],
          ),
        ),
        if (note.labels != null && _isGridView == false && !kIsWeb ||
            note.labels != null && kIsWeb)
          Expanded(
            flex: !kIsWeb ? 2 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: Colors.blue.withOpacity(0),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  for (int i = 0; i < note.labels!.length; i++)
                    if (i < 3)
                      Chip(
                        label: Text(note.labels![i]),
                        backgroundColor: Colors.blue,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  for (int i = 0; i < note.labels!.length; i++)
                    if (i == 3)
                      const Chip(
                        label: Text('...'),
                        backgroundColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ),
          ),
      ],
    );

    return Card(
      child: InkWell(
        onTap: () {
          if (note.isLock == false) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(note: note),
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                String enteredPassword = '';

                return AlertDialog(
                  title: const Text('Enter Password'),
                  content: TextField(
                    obscureText: true,
                    onChanged: (value) {
                      enteredPassword = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'password',
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Submit'),
                      onPressed: () {
                        if (enteredPassword == note.password) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoteDetailScreen(note: note),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Incorrect Password'),
                                content: const Text(
                                    'The entered password is incorrect.'),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
              color: sectionColor, borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(5),
          child: Stack(
            children: [
              noteSection,
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(sectionIcon),
                  color: note.isPriority ? Colors.red : Colors.grey,
                  onPressed: () {
                    setState(() {
                      note.isPriority = !note.isPriority;
                      updateNotePriority(note, note.isPriority);
                    });
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 0,
                child: IconButton(
                  icon: note.isLock
                      ? const Icon(Icons.lock)
                      : const Icon(Icons.lock_open),
                  color: note.isLock ? Colors.red : Colors.black,
                  onPressed: () {},
                ),
              ),
              Positioned(
                top: 80,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () async {
                    bool confirmDelete = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this note?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true) {
                      await deleteNote(note);
                      await fetchNotesFromFirestore();
                      setState(() {
                        // Perform any additional state updates if necessary
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// add note function
  Future<void> _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNoteScreen()),
    );
    if (result != null) {
      setState(() {
        if (result is Note) {
          // Check if the result is of type Note
          notes.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // toggle Icons for list or grid

    final viewToggleIcon =
        _isGridView ? const Icon(Icons.view_list) : const Icon(Icons.grid_view);

    final viewToggleFunction = _isGridView ? _toggleView : _toggleView;

    final viewToggleTooltip =
        _isGridView ? 'Switch to List View' : 'Switch to Grid View';

    final viewToggleFab = FloatingActionButton(
      heroTag: "btnChangeGridview",
      onPressed: viewToggleFunction,
      tooltip: viewToggleTooltip,
      child: viewToggleIcon,
    );
    final addNoteFab = FloatingActionButton(
      heroTag: "btnAddNote",
      onPressed: () {
        if (user.emailVerified) {
          _addNote();
        } else {
          if (notes.length + 1 <= 5 && !user.emailVerified) {
            _addNote();
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Verify Email'),
                  content: const Text(
                      'Please verify your email to create more notes.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }
      },
      tooltip: 'Add a new note',
      child: const Icon(Icons.add),
    );

    final notesListView = ListView.builder(
      itemCount: notes.length,
      itemBuilder: _buildNoteItem,
    );

    final notesGridView = GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: !kIsWeb ? 2 : 3,
        childAspectRatio: !kIsWeb ? 1.5 / 1 : 2 / 1,
      ),
      itemCount: notes.length,
      itemBuilder: _buildNoteItem,
    );

    final notesView = _isGridView ? notesGridView : notesListView;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: user.emailVerified
              ? const Icon(Icons.verified)
              : const Icon(Icons.disabled_by_default),
          onPressed: () async {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null && user.emailVerified) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Email Verified'),
                    content:
                        const Text('Your email has already been verified.'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  );
                },
              );
            } else {
              await checkEmailVerification();
            }
          },
        ),
        automaticallyImplyLeading: false,
        title: Text('Here your task, ${user.email ?? 'Anonymous'}'),
        actions: [
          IconButton(
            onPressed: () {
              _showSearchModal();
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              fetchNotesFromFirestore();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                              selectedFont: notes.isEmpty
                                  ? widget.selectedFont
                                  : notes[0].fontStyle,
                              selectedFontSize: notes.isEmpty
                                  ? widget.selectedFontSize
                                  : notes[0].fontSize,
                            )));
              }),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notesView,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          viewToggleFab,
          const SizedBox(height: 16),
          addNoteFab,
        ],
      ),
    );
  }
}
