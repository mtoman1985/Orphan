import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/child.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'orphan.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create children table
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        dateOfBirth TEXT,
        childIdNumber TEXT NOT NULL,
        fatherName TEXT,
        fatherIdNumber TEXT,
        motherName TEXT,
        motherIdNumber TEXT,
        motherStatus TEXT DEFAULT 'Alive',
        healthStatus TEXT DEFAULT 'Healthy',
        disabilityType TEXT,
        siblings TEXT,
        documents TEXT,
        sponsor TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create sponsors table
    await db.execute('''
      CREATE TABLE sponsors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create documents table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        uploadedAt TEXT NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id)
      )
    ''');
  }

  // ===== Children Operations =====

  /// Insert a new child into the database
  Future<void> insertChild(Child child) async {
    final db = await database;
    await db.insert(
      'children',
      {
        'id': child.id,
        'fullName': child.fullName,
        'dateOfBirth': child.dateOfBirth?.toIso8601String(),
        'childIdNumber': child.childIdNumber,
        'fatherName': child.fatherName,
        'fatherIdNumber': child.fatherIdNumber,
        'motherName': child.motherName,
        'motherIdNumber': child.motherIdNumber,
        'motherStatus': child.motherStatus,
        'healthStatus': child.healthStatus,
        'disabilityType': child.disabilityType,
        'siblings': child.siblings.toString(),
        'documents': child.documents.map((d) => d.toJson()).toString(),
        'sponsor': child.sponsor?.toJson().toString(),
        'createdAt': child.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all children from the database
  Future<List<Child>> getAllChildren() async {
    final db = await database;
    final maps = await db.query('children');
    return List.generate(maps.length, (i) {
      return Child(
        id: maps[i]['id'] as String,
        fullName: maps[i]['fullName'] as String,
        dateOfBirth: maps[i]['dateOfBirth'] != null
            ? DateTime.parse(maps[i]['dateOfBirth'] as String)
            : null,
        childIdNumber: maps[i]['childIdNumber'] as String,
        fatherName: maps[i]['fatherName'] as String? ?? '',
        fatherIdNumber: maps[i]['fatherIdNumber'] as String? ?? '',
        motherName: maps[i]['motherName'] as String? ?? '',
        motherIdNumber: maps[i]['motherIdNumber'] as String? ?? '',
        motherStatus: maps[i]['motherStatus'] as String? ?? 'Alive',
        healthStatus: maps[i]['healthStatus'] as String? ?? 'Healthy',
        disabilityType: maps[i]['disabilityType'] as String?,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
      );
    });
  }

  /// Get a specific child by ID
  Future<Child?> getChild(String id) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Child(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      childIdNumber: map['childIdNumber'] as String,
      fatherName: map['fatherName'] as String? ?? '',
      fatherIdNumber: map['fatherIdNumber'] as String? ?? '',
      motherName: map['motherName'] as String? ?? '',
      motherIdNumber: map['motherIdNumber'] as String? ?? '',
      motherStatus: map['motherStatus'] as String? ?? 'Alive',
      healthStatus: map['healthStatus'] as String? ?? 'Healthy',
      disabilityType: map['disabilityType'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Update an existing child
  Future<void> updateChild(Child child) async {
    final db = await database;
    await db.update(
      'children',
      {
        'fullName': child.fullName,
        'dateOfBirth': child.dateOfBirth?.toIso8601String(),
        'childIdNumber': child.childIdNumber,
        'fatherName': child.fatherName,
        'fatherIdNumber': child.fatherIdNumber,
        'motherName': child.motherName,
        'motherIdNumber': child.motherIdNumber,
        'motherStatus': child.motherStatus,
        'healthStatus': child.healthStatus,
        'disabilityType': child.disabilityType,
      },
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  /// Delete a child by ID
  Future<void> deleteChild(String id) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search children by name
  Future<List<Child>> searchChildren(String query) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'fullName LIKE ?',
      whereArgs: ['%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Child(
        id: maps[i]['id'] as String,
        fullName: maps[i]['fullName'] as String,
        dateOfBirth: maps[i]['dateOfBirth'] != null
            ? DateTime.parse(maps[i]['dateOfBirth'] as String)
            : null,
        childIdNumber: maps[i]['childIdNumber'] as String,
        fatherName: maps[i]['fatherName'] as String? ?? '',
        fatherIdNumber: maps[i]['fatherIdNumber'] as String? ?? '',
        motherName: maps[i]['motherName'] as String? ?? '',
        motherIdNumber: maps[i]['motherIdNumber'] as String? ?? '',
        motherStatus: maps[i]['motherStatus'] as String? ?? 'Alive',
        healthStatus: maps[i]['healthStatus'] as String? ?? 'Healthy',
        disabilityType: maps[i]['disabilityType'] as String?,
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
      );
    });
  }

  /// Close the database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
