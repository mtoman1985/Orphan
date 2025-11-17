import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/child.dart';
import '../models/sponsor.dart';

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
        sponsorId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create sponsors table
    await db.execute('''
      CREATE TABLE sponsors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL DEFAULT 0.0,
        startDate TEXT NOT NULL,
        relationship TEXT,
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
        'sponsorId': child.sponsor?.id,
        'createdAt': child.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
        'sponsorId': child.sponsor?.id,
      },
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<void> deleteChild(String id) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  // ===== Sponsors Operations =====

  Future<void> insertSponsor(Sponsor sponsor) async {
    final db = await database;
    await db.insert(
      'sponsors',
      {
        'id': sponsor.id,
        'name': sponsor.name,
        'amount': sponsor.amount,
        'startDate': sponsor.startDate.toIso8601String(),
        'relationship': sponsor.relationship,
        'email': sponsor.email,
        'phone': sponsor.phone,
        'address': sponsor.address,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Sponsor>> getAllSponsors() async {
    final db = await database;
    final maps = await db.query('sponsors');
    return List.generate(maps.length, (i) {
      return Sponsor(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        amount: (maps[i]['amount'] as num?)?.toDouble() ?? 0.0,
        startDate: DateTime.parse(maps[i]['startDate'] as String),
        relationship: maps[i]['relationship'] as String? ?? '',
        email: maps[i]['email'] as String?,
        phone: maps[i]['phone'] as String?,
        address: maps[i]['address'] as String?,
      );
    });
  }

  Future<Sponsor?> getSponsor(String id) async {
    final db = await database;
    final maps = await db.query(
      'sponsors',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Sponsor(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(map['startDate'] as String),
      relationship: map['relationship'] as String? ?? '',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  Future<void> updateSponsor(Sponsor sponsor) async {
    final db = await database;
    await db.update(
      'sponsors',
      {
        'name': sponsor.name,
        'amount': sponsor.amount,
        'startDate': sponsor.startDate.toIso8601String(),
        'relationship': sponsor.relationship,
        'email': sponsor.email,
        'phone': sponsor.phone,
        'address': sponsor.address,
      },
      where: 'id = ?',
      whereArgs: [sponsor.id],
    );
  }

  Future<void> deleteSponsor(String id) async {
    final db = await database;
    await db.delete(
      'sponsors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== Link/Unlink Sponsor to Child =====

  Future<void> linkSponsorToChild(String childId, String sponsorId) async {
    final db = await database;
    await db.update(
      'children',
      {'sponsorId': sponsorId},
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  Future<void> unlinkSponsorFromChild(String childId) async {
    final db = await database;
    await db.update(
      'children',
      {'sponsorId': null},
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  Future<Sponsor?> getChildSponsor(String childId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );

    if (maps.isEmpty) return null;

    final sponsorId = maps.first['sponsorId'] as String?;
    if (sponsorId == null) return null;

    return getSponsor(sponsorId);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
