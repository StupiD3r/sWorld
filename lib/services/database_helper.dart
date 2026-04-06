import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'sworld_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUserByUsername(String username) async {
    final db = await database;
    return await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<List<Map<String, dynamic>>> getUserByEmail(String email) async {
    final db = await database;
    return await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<bool> usernameExists(String username) async {
    final users = await getUserByUsername(username);
    return users.isNotEmpty;
  }

  Future<bool> emailExists(String email) async {
    final users = await getUserByEmail(email);
    return users.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> validateLogin(String emailOrUsername, String password) async {
    final db = await database;
    return await db.query(
      'users',
      where: '(email = ? OR username = ?) AND password = ?',
      whereArgs: [emailOrUsername, emailOrUsername, password],
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'created_at DESC');
  }
}
