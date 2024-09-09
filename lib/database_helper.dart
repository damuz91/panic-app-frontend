import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'contacts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone TEXT
      )
    ''');
  }

  // Insertar nuevo contacto
  Future<void> insertContacto(Map<String, String> contacto) async {
    final db = await database;
    await db.insert('contacts', contacto);
  }

  // Obtener todos los contactos
  Future<List<Map<String, dynamic>>> getContactos() async {
    final db = await database;
    return await db.query('contacts');
  }

  // Eliminar contacto por ID
  Future<void> deleteContacto(int id) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
