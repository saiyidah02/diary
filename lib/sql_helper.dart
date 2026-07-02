import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  // Create tables
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE diary(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        feeling TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);

    await database.execute("""CREATE TABLE daily_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        text TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

  // Open database
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'diaryawie.db',
      version: 3,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
      onUpgrade: (sql.Database database, int oldVersion, int newVersion) async {
        if (oldVersion < 3) {
          await database.execute("""CREATE TABLE IF NOT EXISTS daily_goals(
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              text TEXT NOT NULL,
              completed INTEGER NOT NULL DEFAULT 0,
              createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """);
        }
      },
    );
  }

  // Create new diary
  static Future<int> createDiary(String feeling, String? description) async {
    final db = await SQLHelper.db();
    final data = {'feeling': feeling, 'description': description};
    return db.insert('diary', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  // Read all diaries
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await SQLHelper.db();
    return db.query('diary', orderBy: 'id DESC');
  }

  // Read single diary
  static Future<List<Map<String, dynamic>>> getDiary(int id) async {
    final db = await SQLHelper.db();
    return db.query('diary', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update diary
  static Future<int> updateDiary(
      int id, String feeling, String? description) async {
    final db = await SQLHelper.db();
    final data = {
      'feeling': feeling,
      'description': description,
      'createdAt': DateTime.now().toString()
    };
    return db.update('diary', data, where: "id = ?", whereArgs: [id]);
  }

  // Delete diary
  static Future<void> deleteDiary(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("diary", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting a diary: $err");
    }
  }

  // Create goal
  static Future<int> createGoal(String text) async {
    final db = await SQLHelper.db();
    return db.insert('daily_goals', {'text': text, 'completed': 0});
  }

  // Read goals
  static Future<List<Map<String, dynamic>>> getGoals() async {
    final db = await SQLHelper.db();
    return db.query('daily_goals', orderBy: 'id ASC');
  }

  // Update goal
  static Future<int> updateGoal(int id, {required bool completed}) async {
    final db = await SQLHelper.db();
    return db.update(
      'daily_goals',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
