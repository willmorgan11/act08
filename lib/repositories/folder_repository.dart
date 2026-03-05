import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';

// CREATE - Insert a new folder
class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.insert('folders', folder.toMap());
  }

  // READ - Get all folders
  Future<List<Folder>> getAllFolders() async {
    final db = await _dbHelper.database;
    final maps = await db.query('folders', orderBy: 'id ASC');
    return maps.map((m) => Folder.fromMap(m)).toList();
  }

  // READ - Get a single folder by ID
  Future<Folder?> getFolderById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('folders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  // UPDATE - Update an existing folder
  Future<int> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  // DELETE - Delete a folder and all associated cards
  Future<int> deleteFolder(int id) async {
    final db = await _dbHelper.database;
    // ON DELETE CASCADE handles cards automatically
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // Get folder count
  Future<int> getFolderCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM folders');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}