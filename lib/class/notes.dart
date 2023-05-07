class Note {
  final int id;
  final String title;
  final String content;
  final List<String>? filesPath;
  final DateTime selectedDate;
  final double fontSize;
  final String fontStyle;
  bool isPriority;
  String? password;
  List<String>? labels;
  bool isLock;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.selectedDate,
    this.isPriority = false,
    this.isLock=false,
    this.filesPath,
    this.fontSize = 15,
    this.fontStyle = "Times New Roman",
    this.password,
    this.labels,
  });
}
