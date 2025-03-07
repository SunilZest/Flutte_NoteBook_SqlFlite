import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Model
class Note {
  int? id;
  String title;
  String description;

  Note({this.id, required this.title, required this.description});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
        id: map['id'], title: map['title'], description: map['description']);
  }
}

// Database Helper
class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    var dir = await getApplicationDocumentsDirectory();
    var path = join(dir.path, 'notes.db');
    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT)');
        });
  }

  Future<int> insertNote(Note note) async {
    var db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    var db = await database;
    var result = await db.query('notes');
    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<int> updateNote(Note note) async {
    var db = await database;
    return await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    var db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

// Controller
class NoteController extends GetxController {
  var notes = <Note>[].obs;
  DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  void loadNotes() async {
    notes.value = await dbHelper.getNotes();
  }

  void addNote(String title, String description) async {
    await dbHelper.insertNote(Note(title: title, description: description));
    loadNotes();
  }

  void updateNote(Note note) async {
    await dbHelper.updateNote(note);
    loadNotes();
  }

  void deleteNote(int id) async {
    await dbHelper.deleteNote(id);
    loadNotes();
  }
}

// UI
class NotesScreen extends StatelessWidget {
  final NoteController controller = Get.put(NoteController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("To-Do Notes")),
      body: Obx(() => ListView.builder(
        itemCount: controller.notes.length,
        itemBuilder: (context, index) {
          var note = controller.notes[index];
          return ListTile(
            title: Text(note.title),
            subtitle: Text(note.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showNoteDialog(context, note)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => controller.deleteNote(note.id!)),
              ],
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showNoteDialog(context),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, [Note? note]) {
    var titleController = TextEditingController(text: note?.title ?? "");
    var descController = TextEditingController(text: note?.description ?? "");

    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(note == null ? "Add Note" : "Edit Note"),
          content: Column(
            children: [
              CupertinoTextField(controller: titleController, placeholder: "Title"),
              CupertinoTextField(controller: descController, placeholder: "Description"),
            ],
          ),
          actions: [
            CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Get.back()),
            CupertinoDialogAction(
                child: const Text("Save"),
                onPressed: () {
                  if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                    if (note == null) {
                      controller.addNote(titleController.text, descController.text);
                    } else {
                      controller.updateNote(Note(
                          id: note.id,
                          title: titleController.text,
                          description: descController.text));
                    }
                  }
                  Get.back();
                }),
          ],
        ));
  }
}

void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: NotesScreen(),
  ));
}
