/*
 * Copyright 2015 Blanyal D'Souza.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Database configuration
  static const String _databaseName = 'ReminderDatabase.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'ReminderTable';

  // Column names
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnDate = 'date';
  static const String columnTime = 'time';
  static const String columnRepeat = 'repeat';
  static const String columnRepeatNo = 'repeat_no';
  static const String columnRepeatType = 'repeat_type';
  static const String columnActive = 'active';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnTime TEXT NOT NULL,
        $columnRepeat INTEGER NOT NULL DEFAULT 0,
        $columnRepeatNo INTEGER NOT NULL DEFAULT 1,
        $columnRepeatType TEXT NOT NULL DEFAULT 'hour',
        $columnActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // Add a new reminder
  Future<int> addReminder(Reminder reminder) async {
    final db = await database;
    final map = reminder.toMap();
    map.remove('id'); // Remove id so it's auto-generated
    return await db.insert(_tableName, map);
  }

  // Get a single reminder by ID
  Future<Reminder?> getReminder(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Reminder.fromMap(maps.first);
    }
    return null;
  }

  // Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final maps = await db.query(_tableName);
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  // Update a reminder
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      _tableName,
      reminder.toMap(),
      where: '$columnId = ?',
      whereArgs: [reminder.id],
    );
  }

  // Delete a reminder
  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete multiple reminders
  Future<int> deleteReminders(List<int> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      _tableName,
      where: '$columnId IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Get count of reminders
  Future<int> getRemindersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}