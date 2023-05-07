import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notemanagement_app/screens/my_home_page.dart';
import 'package:notemanagement_app/screens/signin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notemanagement_app/screens/change_password_screen.dart';
import 'package:notemanagement_app/screens/trash_bin_screen.dart';

class SettingsScreen extends StatefulWidget {
  final double selectedFontSize;
  final String selectedFont;

  const SettingsScreen({
    Key? key,
    required this.selectedFontSize,
    required this.selectedFont,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _selectedFontSize = 15;
  String _selectedFont = 'Times New Roman';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFontSize = widget.selectedFontSize;
    _selectedFont = widget.selectedFont;
  }

  final user = FirebaseAuth.instance.currentUser!;

  Future<void> updateNotesFontStyleAndSize(
    String fontStyle,
    double fontSize,
  ) async {
    final collectionRef = FirebaseFirestore.instance.collection(user.uid);

    // Get all notes
    final notesSnapshot = await collectionRef.get();
    final notesDocs = notesSnapshot.docs;

    // Update each note
    final batch = FirebaseFirestore.instance.batch();
    for (final noteDoc in notesDocs) {
      final noteData = noteDoc.data();

      // Update font style and size
      noteData['fontStyle'] = fontStyle;
      noteData['fontSize'] = fontSize;

      // Add update operation to batch
      batch.update(noteDoc.reference, noteData);
    }

    // Commit batch update
    await batch.commit();
  }

  void _showFontAndSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose the font you want',
                    style: TextStyle(
                      fontSize: widget.selectedFontSize,
                      color: Colors.grey,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: DropdownButton(
                        value: _selectedFont,
                        items: [
                          'Times New Roman',
                          'Roboto',
                          'Tahoma',
                          'Calibri',
                        ].map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFont = value!;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Font Size:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.selectedFontSize,
                    ),
                  ),
                  RadioListTile<double>(
                    title: const Text('15'),
                    value: 15,
                    groupValue: _selectedFontSize,
                    onChanged: (value) {
                      setState(() {
                        _selectedFontSize = value!;
                      });
                    },
                  ),
                  RadioListTile<double>(
                    title: const Text('18'),
                    value: 18,
                    groupValue: _selectedFontSize,
                    onChanged: (value) {
                      setState(() {
                        _selectedFontSize = value!;
                      });
                    },
                  ),
                  RadioListTile<double>(
                    title: const Text('24'),
                    value: 24,
                    groupValue: _selectedFontSize,
                    onChanged: (value) {
                      setState(() {
                        _selectedFontSize = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    await updateNotesFontStyleAndSize(
                        _selectedFont, _selectedFontSize);

                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => MyHomePage(
                          selectedFontSize: _selectedFontSize,
                          selectedFont: _selectedFont,
                        ),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator() // Display loading indicator
                      : const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListView(
              children: <Widget>[
                ListTile(
                  title: Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: widget.selectedFontSize,
                      fontFamily: widget.selectedFont,
                    ),
                  ),
                  leading: const Icon(Icons.change_circle),
                  onTap: () {
                    // Sign out the user he

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                ListTile(
                    title: Text(
                      'Change Font and Size',
                      style: TextStyle(
                        fontSize: widget.selectedFontSize,
                        fontFamily: widget.selectedFont,
                      ),
                    ),
                    leading: const Icon(Icons.text_fields),
                    onTap: () {
                      setState(() {
                        _showFontAndSizeDialog();
                      });
                    }),
                ListTile(
                  title: Text(
                    'Trash Bin',
                    style: TextStyle(
                      fontSize: widget.selectedFontSize,
                      fontFamily: widget.selectedFont,
                    ),
                  ),
                  leading: const Icon(Icons.delete_forever),
                  onTap: () {
                    // Sign out the user he

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TrashBinScreen()),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: widget.selectedFontSize,
                      fontFamily: widget.selectedFont,
                    ),
                  ),
                  leading: const Icon(Icons.logout),
                  onTap: () async {
                    // Sign out the user here
                    await FirebaseAuth.instance.signOut();

                    // Remove all screens from the stack and navigate to SignInScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignInScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            );
          },
        ) // <--- Added closing bracket here
        );
  }
}
