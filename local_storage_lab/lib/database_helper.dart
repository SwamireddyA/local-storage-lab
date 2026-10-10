
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = 'MyDatabase.db';
  static const _databaseVersion = 2;

  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';

  late Database _db;

  Future<void> init() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createGuestTable(db);
    await _createNewTables(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Preserve the existing my_table and its rows.
      await _createNewTables(db);
    }
  }

  Future<void> _createGuestTable(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES folders(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cards_folder_id
      ON cards(folder_id)
    ''');
  }

  // Existing guest-table methods

  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table, orderBy: '$columnId ASC');
  }

  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final int id = row[columnId] as int;
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Folder methods

  Future<int> insertFolder(String name) async {
    return await _db.insert('folders', {
      'name': name.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFoldersWithCounts() async {
    return await _db.rawQuery('''
      SELECT folders.*, COUNT(cards.id) AS card_count
      FROM folders
      LEFT JOIN cards ON cards.folder_id = folders.id
      GROUP BY folders.id
      ORDER BY folders.id ASC
    ''');
  }

  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Card methods

  Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    return await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertCard({
    required String title,
    required String suit,
    String notes = '',
    String? imageRef,
    required int folderId,
  }) async {
    return await _db.insert('cards', {
      'title': title.trim(),
      'suit': suit.trim(),
      'notes': notes.trim(),
      'image_ref': imageRef,
      'folder_id': folderId,
    });
  }

  Future<int> updateCard({
    required int id,
    required String title,
    required String suit,
    String notes = '',
    String? imageRef,
    required int folderId,
  }) async {
    return await _db.update(
      'cards',
      {
        'title': title.trim(),
        'suit': suit.trim(),
        'notes': notes.trim(),
        'image_ref': imageRef,
        'folder_id': folderId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) async {
    return await _db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
