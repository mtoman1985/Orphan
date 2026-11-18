import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform, Directory, File;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/country.dart';
import '../models/child.dart';
import '../models/sponsor.dart';
import '../models/payment.dart';
import '../models/city.dart';
import '../models/organization.dart';
import 'settings_service.dart';
import '../models/user.dart';
import 'github_storage_service.dart';
import 'web_cache_service.dart';
import 'firebase_sync_service.dart';
import '../models/finance/customer.dart';
import '../models/finance/item.dart';
import '../models/finance/invoice.dart';
import '../models/finance/finance_payment.dart';
import '../models/finance/purchase.dart';
import '../models/finance/sale.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();

  Database? _db;
  bool _isInitializing = false;

  void _scheduleAutomaticSync() {
    if (!kIsWeb) FirebaseSyncService().scheduleAutomaticSync();
  }

  Map<String, dynamic> _snakeToCamelMap(Map<String, dynamic> snakeMap) {
    final camelMap = <String, dynamic>{};
    snakeMap.forEach((key, value) {
      if (key == 'id' || key == 'sponsor_id') {
        camelMap['id'] = value.toString();
        return;
      }

      String newKey =
          key.split('_').asMap().entries.map((entry) {
            if (entry.key == 0) return entry.value;
            if (entry.value.isEmpty) return '';
            return entry.value[0].toUpperCase() + entry.value.substring(1);
          }).join();

      if ((newKey == 'documents' ||
              newKey == 'siblings' ||
              newKey == 'sponsor') &&
          value is String &&
          value.isNotEmpty) {
        try {
          camelMap[newKey] = json.decode(value);
        } catch (_) {
          camelMap[newKey] = value;
        }
      } else {
        camelMap[newKey] = value;
      }
    });
    return camelMap;
  }

  Map<String, dynamic> _camelToSnakeMap(Map<String, dynamic> camelMap) {
    final snakeMap = <String, dynamic>{};
    camelMap.forEach((key, value) {
      final newKey = key.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => '_${m.group(1)!.toLowerCase()}',
      );
      snakeMap[newKey] = value;
    });
    return snakeMap;
  }

  Future<void> init() async {
    if (kIsWeb) {
      print(
        'ℹ️ [SqliteService] SQLite is disabled on Web. Using Firebase only.',
      );
      return;
    }

    if (_db != null) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dataPath = await SettingsService.getEffectiveDataPath();
      final dbDir = Directory(dataPath);
      if (!await dbDir.exists()) await dbDir.create(recursive: true);
      final dbPath = p.join(dbDir.path, 'orphan.db');

      _db = await openDatabase(
        dbPath,
        version: 26,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      await _ensureChildrenColumns();
      await _ensureSponsorColumns(_db!);
      await _ensureDefaultDataLoaded();

      // Safety check: ensure is_synced column exists in users table
      try {
        final userCols = await _db!.rawQuery('PRAGMA table_info(users)');
        final colNames = userCols.map((c) => c['name'] as String).toSet();
        if (!colNames.contains('is_synced')) {
          await _db!.execute(
            'ALTER TABLE users ADD COLUMN is_synced INTEGER DEFAULT 0',
          );
          await _db!.update('users', {'is_synced': 1});
          print(
            '✅ [SqliteService] Added missing is_synced column to users table',
          );
        }
        if (!colNames.contains('created_by')) {
          await _db!.execute('ALTER TABLE users ADD COLUMN created_by TEXT');
          print(
            '✅ [SqliteService] Added missing created_by column to users table',
          );
        }
        if (!colNames.contains('updated_by')) {
          await _db!.execute('ALTER TABLE users ADD COLUMN updated_by TEXT');
          print(
            '✅ [SqliteService] Added missing updated_by column to users table',
          );
        }
      } catch (e) {
        print('⚠️ [SqliteService] Error ensuring users table columns: $e');
      }

      // FORCE UPDATE ADMIN PASSWORD to 0599@@
      await _db!.update(
        'users',
        {'password': '0599@@'},
        where: 'id = ?',
        whereArgs: ['admin_1'],
      );

      print('✅ [SqliteService] Database initialization complete');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _ensureChildrenColumns([Database? database]) async {
    final db = database ?? _db;
    if (db == null) return;

    final existingColumns =
        (await db.rawQuery(
          'PRAGMA table_info(children)',
        )).map((column) => column['name'] as String).toSet();
    final modelColumns =
        Child(id: 'schema-check', childIdNumber: 'schema-check').toJson();

    for (final column in modelColumns.keys) {
      if (column == 'id' || existingColumns.contains(column)) continue;
      final type = column == 'is_synced' ? 'INTEGER DEFAULT 0' : 'TEXT';
      await db.execute('ALTER TABLE children ADD COLUMN $column $type');
      print('✅ [SqliteService] Repaired missing children column: $column');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        id TEXT NOT NULL PRIMARY KEY UNIQUE,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        grand_father_name TEXT,
        birth_country TEXT,
        birth_city TEXT,
        national_id TEXT,
        date_of_birth TEXT,
        child_id_number TEXT,
        country TEXT,
        city TEXT,
        street TEXT,
        guardian_name TEXT,
        guardian_address TEXT,
        guardian_relationship TEXT,
        guardian_phone TEXT,
        education_level TEXT,
        grade TEXT,
        university_year TEXT,
        university_college_name TEXT,
        college_specialization TEXT,
        sponsor_linked_at TEXT,
        father_name TEXT,
        father_id_number TEXT,
        father_status TEXT,
        father_death_date TEXT,
        father_death_certificate_path TEXT,
        father_death_certificate_file_name TEXT,
        mother_name TEXT,
        mother_id_number TEXT,
        mother_status TEXT,
        mother_death_date TEXT,
        mother_death_certificate_path TEXT,
        mother_death_certificate_file_name TEXT,
        child_photo_path TEXT,
        child_photo_file_name TEXT,
        mother_id_photo_path TEXT,
        mother_id_photo_file_name TEXT,
        guardian_id_photo_path TEXT,
        guardian_id_photo_file_name TEXT,
        gender TEXT,
        health_status TEXT,
        disability_type TEXT,
        special_needs TEXT,
        siblings TEXT,
        documents TEXT,
        sponsor TEXT,
        created_at TEXT,
        updated_at TEXT,
        created_by TEXT,
        updated_by TEXT,
        payment_method TEXT,
        bank_name TEXT,
        bank_account_number TEXT,
        bank_iban TEXT,
        bank_account_holder_name TEXT,
        wallet_name TEXT,
        wallet_number TEXT,
        wallet_holder_name TEXT,
        father_death_cause TEXT,
        mother_death_cause TEXT,
        school_name TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE sponsors (
        sponsor_id TEXT PRIMARY KEY,
        name TEXT,
        sponsor_category TEXT NOT NULL DEFAULT 'individual',
        start_date TEXT,
        relationship TEXT,
        amount REAL,
        currency TEXT,
        end_date TEXT,
        end_reason TEXT,
        organization_id INTEGER,
        organization_name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        is_ongoing INTEGER,
        created_at TEXT,
        updated_at TEXT,
        created_by TEXT,
        updated_by TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE countries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_tr TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        country_id INTEGER NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_tr TEXT NOT NULL,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (country_id) REFERENCES countries (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE supporting_organizations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL UNIQUE,
        name_en TEXT NOT NULL,
        name_tr TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        child_id TEXT,
        sponsor_id TEXT,
        amount REAL NOT NULL,
        currency TEXT,
        paid_at TEXT NOT NULL,
        note TEXT,
        updated_at TEXT,
        created_by TEXT,
        updated_by TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        full_name TEXT,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        permissions TEXT,
        created_at TEXT,
        is_active INTEGER DEFAULT 1,
        updated_at TEXT,
        created_by TEXT,
        updated_by TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // --- FINANCE SYSTEM TABLES (Version 10) ---

    await db.execute('''
      CREATE TABLE customers (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        phone_number TEXT,
        customer_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        unit TEXT,
        item_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_type TEXT,
        currency TEXT,
        currency_transfer REAL,
        payment_method TEXT,
        invoice_date TEXT,
        notes TEXT,
        customer_id INTEGER,
        total REAL,
        total_dollar REAL,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE finance_payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        currency TEXT,
        currency_transfer REAL,
        payment_amount REAL,
        payment_method TEXT,
        payment_date TEXT,
        notes TEXT,
        payment_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        purchase_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        customer_id INTEGER,
        item_id INTEGER,
        quantity REAL,
        unit_price REAL,
        total REAL,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id),
        FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
        FOREIGN KEY(item_id) REFERENCES items(item_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        customer_id INTEGER,
        item_id INTEGER,
        quantity REAL,
        unit_price REAL,
        total REAL,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id),
        FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
        FOREIGN KEY(item_id) REFERENCES items(item_id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            full_name TEXT,
            password TEXT NOT NULL,
            role TEXT DEFAULT 'user',
            permissions TEXT,
            created_at TEXT,
            is_active INTEGER DEFAULT 1,
            updated_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        // Add created_by and updated_by columns to existing tables
        await db.execute('ALTER TABLE children ADD COLUMN created_by TEXT');
        await db.execute('ALTER TABLE children ADD COLUMN updated_by TEXT');

        await db.execute('ALTER TABLE sponsors ADD COLUMN created_by TEXT');
        await db.execute('ALTER TABLE sponsors ADD COLUMN updated_by TEXT');

        await db.execute('ALTER TABLE payments ADD COLUMN created_by TEXT');
        await db.execute('ALTER TABLE payments ADD COLUMN updated_by TEXT');

        await db.execute('ALTER TABLE users ADD COLUMN created_by TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN updated_by TEXT');
      } catch (e) {
        print('Error upgrading DB to version 9: $e');
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute('''
          CREATE TABLE customers (
            customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_name TEXT NOT NULL,
            phone_number TEXT,
            customer_type TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE items (
            item_id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            unit TEXT,
            item_type TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE invoices (
            invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_type TEXT,
            currency TEXT,
            currency_transfer REAL,
            payment_method TEXT,
            invoice_date TEXT,
            notes TEXT,
            customer_id INTEGER,
            total REAL,
            total_dollar REAL,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE finance_payments (
            payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            currency TEXT,
            currency_transfer REAL,
            payment_amount REAL,
            payment_method TEXT,
            payment_date TEXT,
            notes TEXT,
            payment_type TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE purchases (
            purchase_id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_id INTEGER,
            customer_id INTEGER,
            item_id INTEGER,
            quantity REAL,
            unit_price REAL,
            total REAL,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id),
            FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
            FOREIGN KEY(item_id) REFERENCES items(item_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE sales (
            sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_id INTEGER,
            customer_id INTEGER,
            item_id INTEGER,
            quantity REAL,
            unit_price REAL,
            total REAL,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id),
            FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
            FOREIGN KEY(item_id) REFERENCES items(item_id)
          )
        ''');
      } catch (e) {
        print('Error upgrading DB to version 10: $e');
      }
    }
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE children ADD COLUMN special_needs TEXT');
      } catch (e) {
        print('Error upgrading DB to version 11: $e');
      }
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE children ADD COLUMN bank_name TEXT');
        await db.execute(
          'ALTER TABLE children ADD COLUMN bank_account_number TEXT',
        );
        await db.execute('ALTER TABLE children ADD COLUMN bank_iban TEXT');
        await db.execute(
          'ALTER TABLE children ADD COLUMN bank_account_holder_name TEXT',
        );
      } catch (e) {
        print('Error upgrading DB to version 12: $e');
      }
    }
    if (oldVersion < 14) {
      final columnsToAdd = [
        'father_death_cause',
        'mother_death_cause',
        'school_name',
        'father_death_certificate_path',
        'father_death_certificate_file_name',
        'mother_death_certificate_path',
        'mother_death_certificate_file_name',
        'child_photo_file_name',
        'mother_id_photo_file_name',
        'guardian_id_photo_file_name',
        'bank_name',
        'bank_account_number',
        'bank_iban',
        'bank_account_holder_name',
        'special_needs',
        'university_year',
        'university_college_name',
        'sponsor_linked_at',
        'created_by',
        'updated_by',
        'grand_father_name',
        'birth_country',
        'birth_city',
      ];

      for (var col in columnsToAdd) {
        try {
          await db.execute('ALTER TABLE children ADD COLUMN $col TEXT');
          print('✅ [SqliteService] Added missing column to children: $col');
        } catch (e) {
          // Column probably already exists or table is missing
          print(
            'ℹ️ [SqliteService] Column $col already exists in children or skip: $e',
          );
        }
      }

      // Also ensure payments table has audit columns
      final paymentColumns = ['updated_at', 'created_by', 'updated_by'];
      for (var col in paymentColumns) {
        try {
          await db.execute('ALTER TABLE payments ADD COLUMN $col TEXT');
          print('✅ [SqliteService] Added missing column to payments: $col');
        } catch (e) {
          print(
            'ℹ️ [SqliteService] Column $col already exists in payments or skip: $e',
          );
        }
      }
    }

    if (oldVersion < 15) {
      print(
        '🚀 [SqliteService] Migration to version 15: Recreating children table with TEXT id',
      );
      // 1. Rename existing table
      await db.execute('ALTER TABLE children RENAME TO children_old');

      // 2. Create new table with TEXT id
      await db.execute('''
        CREATE TABLE children (
          id TEXT NOT NULL PRIMARY KEY UNIQUE,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          national_id TEXT,
          date_of_birth TEXT,
          child_id_number TEXT,
          country TEXT,
          city TEXT,
          street TEXT,
          guardian_relationship TEXT,
          guardian_phone TEXT,
          education_level TEXT,
          grade TEXT,
          university_year TEXT,
          university_college_name TEXT,
          college_specialization TEXT,
          sponsor_linked_at TEXT,
          father_name TEXT,
          father_id_number TEXT,
          father_status TEXT,
          father_death_date TEXT,
          father_death_cause TEXT,
          father_death_certificate_path TEXT,
          father_death_certificate_file_name TEXT,
          mother_name TEXT,
          mother_id_number TEXT,
          mother_status TEXT,
          mother_death_date TEXT,
          mother_death_cause TEXT,
          mother_death_certificate_path TEXT,
          mother_death_certificate_file_name TEXT,
          child_photo_path TEXT,
          child_photo_file_name TEXT,
          mother_id_photo_path TEXT,
          mother_id_photo_file_name TEXT,
          guardian_id_photo_path TEXT,
          guardian_id_photo_file_name TEXT,
          gender TEXT,
          health_status TEXT,
          disability_type TEXT,
          special_needs TEXT,
          siblings TEXT,
          documents TEXT,
          sponsor TEXT,
          created_at TEXT,
          updated_at TEXT,
          created_by TEXT,
          updated_by TEXT,
          bank_name TEXT,
          bank_account_number TEXT,
          bank_iban TEXT,
          bank_account_holder_name TEXT,
          school_name TEXT
        )
      ''');

      // 3. Migrate data
      try {
        await db.execute('''
          INSERT INTO children (
            id, first_name, last_name, national_id, date_of_birth, child_id_number,
            country, city, street, guardian_relationship, guardian_phone, 
            education_level, grade, university_year, university_college_name,
            sponsor_linked_at, father_name, father_id_number, father_status,
            father_death_date, father_death_cause, father_death_certificate_path,
            father_death_certificate_file_name, mother_name, mother_id_number,
            mother_status, mother_death_date, mother_death_cause,
            mother_death_certificate_path, mother_death_certificate_file_name,
            child_photo_path, child_photo_file_name, mother_id_photo_path,
            mother_id_photo_file_name, guardian_id_photo_path, 
            guardian_id_photo_file_name, gender, health_status, disability_type,
            special_needs, siblings, documents, sponsor, created_at, updated_at,
            created_by, updated_by, bank_name, bank_account_number, bank_iban,
            bank_account_holder_name, school_name
          )
          SELECT 
            CAST(id AS TEXT), first_name, last_name, national_id, date_of_birth, 
            child_id_number, country, city, street, guardian_relationship,
            guardian_phone, education_level, grade, university_year,
            university_college_name, sponsor_linked_at, father_name, 
            father_id_number, father_status, father_death_date, 
            father_death_cause, father_death_certificate_path,
            father_death_certificate_file_name, mother_name, mother_id_number,
            mother_status, mother_death_date, mother_death_cause,
            mother_death_certificate_path, mother_death_certificate_file_name,
            child_photo_path, child_photo_file_name, mother_id_photo_path,
            mother_id_photo_file_name, guardian_id_photo_path,
            guardian_id_photo_file_name, gender, health_status, disability_type,
            special_needs, siblings, documents, sponsor, created_at, updated_at,
            created_by, updated_by, bank_name, bank_account_number, bank_iban,
            bank_account_holder_name, school_name
          FROM children_old
        ''');
        print('✅ [SqliteService] Data migrated to new children table');

        // Optional: Drop old table
        await db.execute('DROP TABLE children_old');

        // Final cleanup for version 15
        await repairDuplicatesInternal(db);
      } catch (e) {
        print('❌ [SqliteService] Error migrating children data: $e');
      }
    }

    if (oldVersion < 16) {
      print(
        '🚀 [SqliteService] Upgrading to version 16: Adding is_synced flag...',
      );
      try {
        await db.execute(
          'ALTER TABLE children ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE sponsors ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE payments ADD COLUMN is_synced INTEGER DEFAULT 0',
        );

        // Mark existing records as synced if we are doing a fresh upgrade
        // (Assuming existing records were previously synced)
        await db.update('children', {'is_synced': 1});
        await db.update('sponsors', {'is_synced': 1});
        await db.update('payments', {'is_synced': 1});
      } catch (e) {
        print(
          '⚠️ [SqliteService] Error adding is_synced column (might already exist): $e',
        );
      }
      if (oldVersion < 17) {
        final tables = [
          'countries',
          'cities',
          'supporting_organizations',
          'customers',
          'items',
          'invoices',
          'finance_payments',
          'purchases',
          'sales',
        ];
        for (var table in tables) {
          try {
            await db.execute(
              'ALTER TABLE $table ADD COLUMN is_synced INTEGER DEFAULT 0',
            );
            // Mark existing as synced
            await db.update(table, {'is_synced': 1});
          } catch (e) {
            print('⚠️ [SqliteService] Error adding is_synced to $table: $e');
          }
        }
      }
    }

    if (oldVersion < 18) {
      print(
        '🚀 [SqliteService] Upgrading to version 18: Fixing children table schema...',
      );
      try {
        // Handle potential datatype mismatch by recreating table with TEXT id
        await db.execute('ALTER TABLE children RENAME TO children_fix');

        // Re-run create for ONLY children if we want to be surgical,
        // but easier to just use the SQL here
        await db.execute('''
          CREATE TABLE children (
            id TEXT NOT NULL PRIMARY KEY UNIQUE,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            national_id TEXT,
            date_of_birth TEXT,
            child_id_number TEXT,
            country TEXT,
            city TEXT,
            street TEXT,
            guardian_relationship TEXT,
            guardian_phone TEXT,
            education_level TEXT,
            grade TEXT,
            university_year TEXT,
            university_college_name TEXT,
            college_specialization TEXT,
            sponsor_linked_at TEXT,
            father_name TEXT,
            father_id_number TEXT,
            father_status TEXT,
            father_death_date TEXT,
            father_death_certificate_path TEXT,
            father_death_certificate_file_name TEXT,
            mother_name TEXT,
            mother_id_number TEXT,
            mother_status TEXT,
            mother_death_date TEXT,
            mother_death_certificate_path TEXT,
            mother_death_certificate_file_name TEXT,
            child_photo_path TEXT,
            child_photo_file_name TEXT,
            mother_id_photo_path TEXT,
            mother_id_photo_file_name TEXT,
            guardian_id_photo_path TEXT,
            guardian_id_photo_file_name TEXT,
            gender TEXT,
            health_status TEXT,
            disability_type TEXT,
            special_needs TEXT,
            siblings TEXT,
            documents TEXT,
            sponsor TEXT,
            created_at TEXT,
            updated_at TEXT,
            created_by TEXT,
            updated_by TEXT,
            bank_name TEXT,
            bank_account_number TEXT,
            bank_iban TEXT,
            bank_account_holder_name TEXT,
            father_death_cause TEXT,
            mother_death_cause TEXT,
            school_name TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        final rows = await db.rawQuery('PRAGMA table_info(children_fix)');
        final fixCols = rows.map((r) => r['name'] as String).toList();
        final commonCols =
            fixCols
                .where(
                  (c) => [
                    'id',
                    'first_name',
                    'last_name',
                    'national_id',
                    'date_of_birth',
                    'child_id_number',
                    'country',
                    'city',
                    'street',
                    'guardian_relationship',
                    'guardian_phone',
                    'education_level',
                    'grade',
                    'university_year',
                    'university_college_name',
                    'sponsor_linked_at',
                    'father_name',
                    'father_id_number',
                    'father_status',
                    'father_death_date',
                    'father_death_cause',
                    'father_death_certificate_path',
                    'father_death_certificate_file_name',
                    'mother_name',
                    'mother_id_number',
                    'mother_status',
                    'mother_death_date',
                    'mother_death_cause',
                    'mother_death_certificate_path',
                    'mother_death_certificate_file_name',
                    'child_photo_path',
                    'child_photo_file_name',
                    'mother_id_photo_path',
                    'mother_id_photo_file_name',
                    'guardian_id_photo_path',
                    'guardian_id_photo_file_name',
                    'gender',
                    'health_status',
                    'disability_type',
                    'special_needs',
                    'siblings',
                    'documents',
                    'sponsor',
                    'created_at',
                    'updated_at',
                    'created_by',
                    'updated_by',
                    'grand_father_name',
                    'birth_country',
                    'birth_city',
                    'bank_name',
                    'bank_account_number',
                    'bank_iban',
                    'bank_account_holder_name',
                    'school_name',
                    'is_synced',
                  ].contains(c),
                )
                .toList();

        final colsStr = commonCols.join(', ');
        await db.execute(
          'INSERT INTO children ($colsStr) SELECT $colsStr FROM children_fix',
        );
        await db.execute('DROP TABLE children_fix');
        print('✅ [SqliteService] children table fixed and data migrated');
      } catch (e) {
        print('⚠️ [SqliteService] Error fixing children table: $e');
      }
    }
    if (oldVersion < 19) {
      print(
        '🚀 [SqliteService] Upgrading to version 19: Adding is_synced to users table...',
      );
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
        // Mark existing as synced
        await db.update('users', {'is_synced': 1});
        print('✅ [SqliteService] Added is_synced column to users table');
      } catch (e) {
        print('⚠️ [SqliteService] Error adding is_synced to users table: $e');
      }
    }
    if (oldVersion < 20) {
      print(
        '🚀 [SqliteService] Upgrading to version 20: Adding financial/wallet columns to children table...',
      );
      final newCols = [
        'payment_method',
        'wallet_name',
        'wallet_number',
        'wallet_holder_name',
      ];
      for (final col in newCols) {
        try {
          await db.execute('ALTER TABLE children ADD COLUMN $col TEXT');
          print('✅ [SqliteService] Added column $col to children table');
        } catch (e) {
          print('⚠️ [SqliteService] Column $col may already exist: $e');
        }
      }
      if (oldVersion < 21) {
        await db.execute(
          'ALTER TABLE children ADD COLUMN college_specialization TEXT',
        );
      }
    }
    if (oldVersion < 22) {
      for (final column in ['guardian_name', 'guardian_address']) {
        try {
          await db.execute('ALTER TABLE children ADD COLUMN $column TEXT');
          print('✅ [SqliteService] Added column $column to children table');
        } catch (e) {
          print('⚠️ [SqliteService] Could not add $column: $e');
        }
      }
    }
    if (oldVersion < 23) {
      await _ensureChildrenColumns(db);
    }
    if (oldVersion < 24) {
      await _ensureSponsorColumns(db);
    }
    if (oldVersion < 25) {
      await _ensureSponsorColumns(db);
    }
    if (oldVersion < 26) {
      await _removeChildIdentityUniqueness(db);
    }
  }

  Future<void> _removeChildIdentityUniqueness(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(children)');
    if (columns.isEmpty) {
      throw StateError(
        'Cannot migrate child records: children table is empty.',
      );
    }

    final columnNames =
        columns.map((column) => column['name'] as String).toList();
    final definitions = columns
        .map((column) {
          final name = column['name'] as String;
          final type = (column['type'] as String?) ?? 'TEXT';
          final primaryKey = (column['pk'] as int? ?? 0) > 0;
          final notNull = column['notnull'] == 1 || primaryKey;
          final defaultValue = column['dflt_value'];
          return '"$name" $type'
              '${primaryKey ? ' PRIMARY KEY' : ''}'
              '${notNull ? ' NOT NULL' : ''}'
              '${defaultValue == null ? '' : ' DEFAULT $defaultValue'}';
        })
        .join(', ');
    final quotedColumns = columnNames.map((name) => '"$name"').join(', ');

    await db.execute('CREATE TABLE children_sync_new ($definitions)');
    await db.execute(
      'INSERT INTO children_sync_new ($quotedColumns) '
      'SELECT $quotedColumns FROM children',
    );
    await db.execute('DROP TABLE children');
    await db.execute('ALTER TABLE children_sync_new RENAME TO children');
  }

  Future<void> _ensureSponsorColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(sponsors)');
    final columns = rows.map((row) => row['name'] as String).toSet();
    const requiredColumns = <String, String>{
      'sponsor_category': "TEXT NOT NULL DEFAULT 'individual'",
      'email': 'TEXT',
      'phone': 'TEXT',
      'address': 'TEXT',
      'end_reason': 'TEXT',
    };
    for (final entry in requiredColumns.entries) {
      if (!columns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE sponsors ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> repairDuplicates() async {
    await init();
    if (_db == null) return;
    await repairDuplicatesInternal(_db!);
  }

  /// Internal repair function that can take a Database object during migration
  Future<void> repairDuplicatesInternal(Database db) async {
    print('🛠️ [SqliteService] Running duplicate repair...');

    // Find children with same child_id_number
    final rows = await db.rawQuery('''
      SELECT child_id_number, COUNT(*) as count 
      FROM children 
      WHERE child_id_number IS NOT NULL AND child_id_number != ''
      GROUP BY child_id_number 
      HAVING count > 1
    ''');

    for (var row in rows) {
      final childIdNum = row['child_id_number'] as String;

      // Get all records for this child_id_number
      final duplicates = await db.query(
        'children',
        where: 'child_id_number = ?',
        whereArgs: [childIdNum],
        orderBy: 'updated_at DESC',
      );

      if (duplicates.length <= 1) continue;

      // Keep the first (most recently updated) and delete others
      for (int i = 1; i < duplicates.length; i++) {
        final toDeleteId = duplicates[i]['id'];
        await db.delete('children', where: 'id = ?', whereArgs: [toDeleteId]);
        print(
          '🗑️ [SqliteService] Deleted duplicate record ID: $toDeleteId for child_id_number: $childIdNum',
        );
      }
    }

    // Also check for national_id duplicates
    final nationalIdRows = await db.rawQuery('''
      SELECT national_id, COUNT(*) as count 
      FROM children 
      WHERE national_id IS NOT NULL AND national_id != ''
      GROUP BY national_id 
      HAVING count > 1
    ''');

    for (var row in nationalIdRows) {
      final nid = row['national_id'] as String;

      final duplicates = await db.query(
        'children',
        where: 'national_id = ?',
        whereArgs: [nid],
        orderBy: 'updated_at DESC',
      );

      if (duplicates.length <= 1) continue;

      for (int i = 1; i < duplicates.length; i++) {
        final toDeleteId = duplicates[i]['id'];
        await db.delete('children', where: 'id = ?', whereArgs: [toDeleteId]);
        print(
          '🗑️ [SqliteService] Deleted duplicate record ID: $toDeleteId for national_id: $nid',
        );
      }
    }
    print('✅ [SqliteService] Duplicate repair complete');
  }

  Future<void> _ensureDefaultDataLoaded() async {
    if (_db == null) return;

    // Default Admin User
    final users = await _db!.query('users', limit: 1);
    if (users.isEmpty) {
      await _db!.insert('users', {
        'id': 'admin_1',
        'username': 'admin',
        'full_name': 'المدير العام',
        'password': '0599@@', // In real apps, store hash
        'role': 'admin',
        'permissions': '[]',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ [SqliteService] Default admin user created');
    }
    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM countries'),
    );
    print('📊 [SqliteService] Countries count before default load: $count');
    if (count == 0) {
      await _insertDefaultCountries(_db!);
      print('✅ [SqliteService] Default countries inserted');
    }
    // Always call this to ensure missing cities are added
    await _insertDefaultCities(_db!);
    // Ensure default finance items are loaded
    await _insertDefaultItems(_db!);

    // Fix standard country codes if they are incorrect
    await _fixStandardCountryCodes(_db!);

    // Verify data after insertion
    final finalCountryCount = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM countries'),
    );
    final finalCityCount = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM cities'),
    );
    print(
      '📊 [SqliteService] Final counts - Countries: $finalCountryCount, Cities: $finalCityCount',
    );
  }

  // --- CHILDREN ---

  Future<List<Child>> listChildren() async {
    if (kIsWeb) {
      return await WebCacheService().getChildren();
    }
    await init();
    if (_db == null) {
      print('⚠️ [SqliteService] Database is null in listChildren');
      return [];
    }
    try {
      final rows = await _db!.query('children', orderBy: 'created_at DESC');
      print('📊 [SqliteService] listChildren: found ${rows.length} rows');

      final list = await Future.wait(
        rows.map((r) async {
          try {
            final child = Child.fromJson(_snakeToCamelMap(r));
            await GitHubStorageService.fixChildPaths(child);
            return child;
          } catch (e) {
            print('❌ [SqliteService] Error parsing child row: $e');
            return null;
          }
        }),
      );
      final filteredList = list.whereType<Child>().toList();
      print(
        '✅ [SqliteService] listChildren: returning ${filteredList.length} children',
      );
      return filteredList;
    } catch (e) {
      print('❌ [SqliteService] Error in listChildren: $e');
      return [];
    }
  }

  Future<void> insertChild(Child child) async {
    if (kIsWeb) {
      final sync = FirebaseSyncService();
      await sync.saveChildToFirebase(child);
      WebCacheService().updateChildInCache(child);
      return;
    }

    if (_db == null) await init();
    if (_db == null) {
      throw StateError(
        'Cannot save child because the local database is unavailable.',
      );
    }
    final map = child.toJson();

    final columns =
        (await _db!.rawQuery(
          'PRAGMA table_info(children)',
        )).map((column) => column['name'] as String).toSet();
    final missingColumns = map.keys.where((key) => !columns.contains(key));
    if (missingColumns.isNotEmpty) {
      throw StateError(
        'Cannot save child: children table is missing columns: '
        '${missingColumns.join(', ')}',
      );
    }

    await _db!.insert(
      'children',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<Child?> getChildById(String id) async {
    if (kIsWeb) {
      final children = await WebCacheService().getChildren();
      try {
        return children.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    await init();
    if (_db == null) return null;
    final rows = await _db!.query(
      'children',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final child = Child.fromJson(_snakeToCamelMap(rows.first));
    await GitHubStorageService.fixChildPaths(child);
    return child;
  }

  Future<Child?> getChildByNationalId(String nationalId) async {
    final cleanId = nationalId.trim();
    if (cleanId.isEmpty) return null;
    if (kIsWeb) {
      final children = await WebCacheService().getChildren();
      try {
        return children.firstWhere((c) => c.nationalId?.trim() == cleanId);
      } catch (_) {
        return null;
      }
    }

    await init();
    if (_db == null) return null;
    final rows = await _db!.query(
      'children',
      where: 'national_id = ?',
      whereArgs: [cleanId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final child = Child.fromJson(_snakeToCamelMap(rows.first));
    await GitHubStorageService.fixChildPaths(child);
    return child;
  }

  Future<void> updateChildSponsorship(
    String childId,
    Sponsor? sponsorship,
  ) async {
    final child = await getChildById(childId);
    if (child == null) return;

    child.sponsor = sponsorship;
    child.sponsorLinkedAt = sponsorship != null ? DateTime.now() : null;
    child.updatedAt = DateTime.now();

    await insertChild(child);
  }

  Future<void> deleteChild(String id) async {
    await init();
    await FirebaseSyncService().deleteChildFromFirebase(id);
    await _db!.delete('children', where: 'id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<List<Child>> getChildrenBySponsorId(String sponsorId) async {
    final all = await listChildren();
    return all
        .where(
          (c) =>
              c.sponsor?.linkedSponsorId == sponsorId ||
              c.sponsor?.id == sponsorId,
        )
        .toList();
  }

  Future<void> updateChildSponsor(String childId, Sponsor? sponsor) async {
    await init();
    if (_db == null) return;
    await _db!.update(
      'children',
      {'sponsor': sponsor != null ? json.encode(sponsor.toJson()) : null},
      where: 'id = ?',
      whereArgs: [childId],
    );
    _scheduleAutomaticSync();
  }

  Future<List<Child>> getUnSponsoredChildren() async {
    final all = await listChildren();
    return all.where((c) => c.sponsor == null).toList();
  }

  // --- SPONSORS ---

  Future<List<Sponsor>> listSponsors() async {
    // On web, use WebCacheService
    if (kIsWeb) {
      print(
        '🌐 [SqliteService] Running on web, using WebCacheService for sponsors',
      );
      final sponsors = await WebCacheService().getSponsors();
      print(
        '📊 [SqliteService] Retrieved ${sponsors.length} sponsors from WebCacheService',
      );
      return sponsors;
    }

    // On desktop, use SQLite
    print('💻 [SqliteService] Running on desktop, using SQLite for sponsors');
    await init();
    if (_db == null) {
      print('⚠️ [SqliteService] Database is null, returning empty list');
      return [];
    }
    final rows = await _db!.query('sponsors', orderBy: 'name ASC');
    print('📊 [SqliteService] Found ${rows.length} sponsors in SQLite');
    return rows.map((r) => Sponsor.fromJson(_snakeToCamelMap(r))).toList();
  }

  Future<Sponsor?> getSponsorById(String id) async {
    if (kIsWeb) {
      final sponsors = await WebCacheService().getSponsors();
      try {
        return sponsors.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }

    await init();
    if (_db == null) return null;
    final rows = await _db!.query(
      'sponsors',
      where: 'sponsor_id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Sponsor.fromJson(_snakeToCamelMap(rows.first));
  }

  Future<void> insertSponsor(Sponsor sponsor) async {
    if (kIsWeb) {
      final firebaseSync = FirebaseSyncService();
      await firebaseSync.saveSponsorToFirebase(sponsor);
      WebCacheService().updateSponsorInCache(sponsor);
      return;
    }

    await init();
    if (_db == null) return;
    final map = sponsor.toJson();

    // Map id to sponsor_id for SQLite
    if (map.containsKey('id')) {
      map['sponsor_id'] = map.remove('id');
    }

    await _db!.insert(
      'sponsors',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<void> deleteSponsor(String id) async {
    if (kIsWeb) {
      final firebaseSync = FirebaseSyncService();
      await firebaseSync.deleteSponsorFromFirebase(id);
      WebCacheService().removeSponsorFromCache(id);
      return;
    }
    await init();
    if (_db == null) return;
    await FirebaseSyncService().deleteSponsorFromFirebase(id);
    await _db!.delete('sponsors', where: 'sponsor_id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  // --- PAYMENTS ---

  Future<List<Payment>> listPayments({String? childId}) async {
    if (kIsWeb) {
      if (childId == null) {
        // Fallback for list all payments on web if needed
        final snapshot =
            await FirebaseFirestore.instance.collectionGroup('payments').get();
        return snapshot.docs
            .map((doc) => Payment.fromJson(doc.data()))
            .toList();
      }
      return await FirebaseSyncService().getPaymentsFromFirebase(childId);
    }
    await init();
    if (_db == null) return [];
    final rows =
        childId == null
            ? await _db!.query('payments', orderBy: 'paid_at DESC')
            : await _db!.query(
              'payments',
              where: 'child_id = ?',
              whereArgs: [childId],
              orderBy: 'paid_at DESC',
            );
    return rows.map((r) => Payment.fromJson(_snakeToCamelMap(r))).toList();
  }

  Future<List<Payment>> listPaymentsBySponsorId(String sponsorId) async {
    if (kIsWeb) {
      return await WebCacheService().getPaymentsForSponsor(sponsorId);
    }
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'payments',
      where: 'sponsor_id = ?',
      whereArgs: [sponsorId],
      orderBy: 'paid_at DESC',
    );
    return rows.map((r) => Payment.fromJson(_snakeToCamelMap(r))).toList();
  }

  Future<void> insertPayment(Payment payment) async {
    if (kIsWeb) {
      await FirebaseSyncService().savePaymentToFirebase(
        payment.childId,
        payment,
      );
      return;
    }
    await init();
    if (_db == null) return;
    await _db!.insert(
      'payments',
      _camelToSnakeMap(payment.toJson()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<void> deletePayment(String id) async {
    await init();
    if (_db == null) return;
    final rows = await _db!.query(
      'payments',
      columns: ['child_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await FirebaseSyncService().deletePaymentFromFirebase(
        rows.first['child_id'] as String,
        id,
      );
    }
    await _db!.delete('payments', where: 'id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<void> deletePaymentsByChildId(String childId) async {
    await init();
    if (_db == null) return;
    final rows = await _db!.query(
      'payments',
      columns: ['id'],
      where: 'child_id = ?',
      whereArgs: [childId],
    );
    for (final row in rows) {
      await FirebaseSyncService().deletePaymentFromFirebase(
        childId,
        row['id'] as String,
      );
    }
    await _db!.delete('payments', where: 'child_id = ?', whereArgs: [childId]);
    _scheduleAutomaticSync();
  }

  // --- COUNTRIES & CITIES ---

  Future<List<Country>> listCountries() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('countries', orderBy: 'name_ar ASC');
    return rows
        .map((r) => Country.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> insertCountry(Country country) async {
    await init();
    if (_db == null) return;
    await _db!.insert(
      'countries',
      country.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<void> deleteCountry(int id) async {
    await init();
    if (_db == null) return;
    final rows = await _db!.query(
      'countries',
      columns: ['code'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await FirebaseSyncService().deleteCloudRecord(
        'countries',
        rows.first['code'] as String,
      );
    }
    await _db!.delete('countries', where: 'id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<void> updateCountryCode(
    int countryId,
    String oldCode,
    String newCode,
    String countryName,
  ) async {
    await init();
    if (_db == null) return;
    await _db!.transaction((txn) async {
      await txn.update(
        'countries',
        {'code': newCode},
        where: 'id = ?',
        whereArgs: [countryId],
      );
      final childrenRes = await txn.query(
        'children',
        where: 'country = ?',
        whereArgs: [countryName],
      );
      for (var child in childrenRes) {
        final childIdNumber = child['child_id_number'] as String?;
        if (childIdNumber != null && childIdNumber.startsWith('IHSAN')) {
          String sequenceNumber = '';
          final match = RegExp(r'(\d{4})$').firstMatch(childIdNumber);
          if (match != null) sequenceNumber = match.group(1)!;
          if (sequenceNumber.isNotEmpty) {
            final newChildId = 'IHSAN$newCode$sequenceNumber';
            await txn.update(
              'children',
              {'child_id_number': newChildId},
              where: 'id = ?',
              whereArgs: [child['id']],
            );
          }
        }
      }
    });
    _scheduleAutomaticSync();
  }

  Future<List<City>> listCities() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('cities', orderBy: 'name_ar ASC');
    return rows
        .map((r) => City.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<List<City>> listCitiesByCountry(int countryId) async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'cities',
      where: 'country_id = ?',
      whereArgs: [countryId],
      orderBy: 'name_ar ASC',
    );
    return rows
        .map((r) => City.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> insertCity(City city) async {
    await init();
    if (_db == null) return;
    await _db!.insert(
      'cities',
      city.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<void> deleteCity(int id) async {
    await init();
    if (_db == null) return;
    await FirebaseSyncService().deleteCloudRecord('cities', id.toString());
    await _db!.delete('cities', where: 'id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<void> loadDefaultCitiesIfEmpty() async {
    await init();
    if (_db == null) return;
    await _insertDefaultCities(_db!);
  }

  // --- ORGANIZATIONS ---

  Future<List<Organization>> listSupportingOrganizations() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'supporting_organizations',
      orderBy: 'name_ar ASC',
    );
    return rows
        .map((r) => Organization.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> insertSupportingOrganization(Organization org) async {
    await init();
    if (_db == null) return;
    await _db!.insert(
      'supporting_organizations',
      org.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
  }

  Future<void> deleteSupportingOrganization(int id) async {
    await init();
    if (_db == null) return;
    await FirebaseSyncService().deleteCloudRecord(
      'supporting_organizations',
      id.toString(),
    );
    await _db!.delete(
      'supporting_organizations',
      where: 'id = ?',
      whereArgs: [id],
    );
    _scheduleAutomaticSync();
  }

  // --- UTILS ---

  Future<String> getNextCountryBasedChildId(
    String countryName, {
    String? knownCode,
  }) async {
    if (kIsWeb) {
      return await FirebaseSyncService().getNextCountryBasedChildId(
        countryName,
        knownCode: knownCode,
      );
    }
    await init();
    if (_db == null) return 'IHSAN990001';

    String code = knownCode ?? '99';

    if (knownCode == null) {
      final countryRes = await _db!.query(
        'countries',
        where: 'name_ar = ?',
        whereArgs: [countryName],
      );
      if (countryRes.isNotEmpty) {
        code = (countryRes.first['code'] as String?) ?? '99';
      }
    }

    // Ensure code is at least 2 digits (e.g. "1" -> "01")
    if (code.length < 2) {
      code = code.padLeft(2, '0');
    }

    final count =
        Sqflite.firstIntValue(
          await _db!.rawQuery(
            'SELECT COUNT(*) FROM children WHERE country = ?',
            [countryName],
          ),
        ) ??
        0;

    // Format: IHSAN + 2-digit Country Code + 4-digit Count (starting from 1)
    return 'IHSAN$code${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<void> exportDatabase(String targetPath) async {
    if (kIsWeb) return;
    await init();
    final path = await SettingsService.getEffectiveDataPath();
    final dbPath = p.join(path, 'orphan.db');
    if (await File(dbPath).exists()) await File(dbPath).copy(targetPath);
  }

  Future<void> importDatabase(String sourcePath) async {
    if (kIsWeb) return;
    final path = await SettingsService.getEffectiveDataPath();
    final dbPath = p.join(path, 'orphan.db');
    await close();
    await File(sourcePath).copy(dbPath);
    _db = null;
    await init();
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> deleteDocument(String id) async {
    await init();
    // Logic for documents table if separated
  }

  // --- PRIVATE HELPERS ---

  Future<void> _fixStandardCountryCodes(Database db) async {
    const corrections = {
      'فلسطين': '01',
      'لبنان': '02',
      'سوريا': '03',
      'الأردن': '04',
      'مصر': '05',
      'تركيا': '06',
    };

    try {
      for (final entry in corrections.entries) {
        final name = entry.key;
        final targetCode = entry.value;

        final rows = await db.query(
          'countries',
          where: 'name_ar = ?',
          whereArgs: [name],
        );

        if (rows.isNotEmpty) {
          final currentCode = rows.first['code'] as String?;
          if (currentCode != targetCode) {
            // Check if target code is free
            final collision = await db.query(
              'countries',
              where: 'code = ?',
              whereArgs: [targetCode],
            );

            if (collision.isEmpty) {
              await db.update(
                'countries',
                {'code': targetCode},
                where: 'name_ar = ?',
                whereArgs: [name],
              );
              print('🔧 Corrected code for $name: $currentCode -> $targetCode');
            } else {
              // If target code is taken by another country (unlikely conflict?), verify ownership
              // ...
              // For now we assume standard codes are prioritized for standard names.
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error in _fixStandardCountryCodes: $e');
    }
  }

  Future<void> _insertDefaultCountries(Database db) async {
    final countries = [
      {
        'name_ar': 'فلسطين',
        'name_en': 'Palestine',
        'name_tr': 'Filistin',
        'code': '01',
      },
      {
        'name_ar': 'لبنان',
        'name_en': 'Lebanon',
        'name_tr': 'Lübnan',
        'code': '02',
      },
      {
        'name_ar': 'سوريا',
        'name_en': 'Syria',
        'name_tr': 'Suriye',
        'code': '03',
      },
      {
        'name_ar': 'الأردن',
        'name_en': 'Jordan',
        'name_tr': 'Ürdün',
        'code': '04',
      },
      {'name_ar': 'مصر', 'name_en': 'Egypt', 'name_tr': 'Mısır', 'code': '05'},
      {
        'name_ar': 'تركيا',
        'name_en': 'Turkey',
        'name_tr': 'Türkiye',
        'code': '06',
      },
    ];
    for (var c in countries) {
      await db.insert(
        'countries',
        c,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _insertDefaultCities(Database db) async {
    final countryMaps = await db.query('countries');
    final countryIdMap = {
      for (var c in countryMaps) c['name_ar'] as String: c['id'] as int,
    };

    // Get existing cities to check before inserting
    final existingCities = await db.query('cities');
    final existingSet =
        existingCities.map((c) => '${c['country_id']}_${c['name_ar']}').toSet();

    final cities = [
      if (countryIdMap.containsKey('فلسطين')) ...[
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'غزة',
          'name_en': 'Gaza',
          'name_tr': 'Gazze',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'القدس',
          'name_en': 'Jerusalem',
          'name_tr': 'Kudüs',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'نابلس',
          'name_en': 'Nablus',
          'name_tr': 'Nablus',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'رام الله',
          'name_en': 'Ramallah',
          'name_tr': 'Ramallah',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'الخليل',
          'name_en': 'Hebron',
          'name_tr': 'El Halil',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'جنين',
          'name_en': 'Jenin',
          'name_tr': 'Cenin',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'طولكرم',
          'name_en': 'Tulkarm',
          'name_tr': 'Tulkarm',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'قلقيلية',
          'name_en': 'Qalqilya',
          'name_tr': 'Kalkilya',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'بيت لحم',
          'name_en': 'Bethlehem',
          'name_tr': 'Beytüllahim',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'أريحا',
          'name_en': 'Jericho',
          'name_tr': 'Eriha',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'رفح',
          'name_en': 'Rafah',
          'name_tr': 'Refah',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'خانيونس',
          'name_en': 'Khan Yunis',
          'name_tr': 'Han Yunus',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'دير البلح',
          'name_en': 'Deir al-Balah',
          'name_tr': 'Deyr el-Belah',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'المغازي',
          'name_en': 'Al-Maghazi',
          'name_tr': 'El-Megazi',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'النصيرات',
          'name_en': 'Al-Nuseirat',
          'name_tr': 'Nuseyrat',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'البريج',
          'name_en': 'Al-Bureij',
          'name_tr': 'El-Bureij',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'الزوايدة',
          'name_en': 'Al-Zawaida',
          'name_tr': 'El-Zevayde',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'بيت لاهيا',
          'name_en': 'Beit Lahia',
          'name_tr': 'Beyt Lahiya',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'بيت حانون',
          'name_en': 'Beit Hanoun',
          'name_tr': 'Beyt Hanun',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'جباليا',
          'name_en': 'Jabalia',
          'name_tr': 'Cebaliye',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'طوباس',
          'name_en': 'Tubas',
          'name_tr': 'Tuba',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'سلفيت',
          'name_en': 'Salfit',
          'name_tr': 'Selfit',
        },
        {
          'country_id': countryIdMap['فلسطين'],
          'name_ar': 'بيرزيت',
          'name_en': 'Birzeit',
          'name_tr': 'Birzeit',
        },
      ],
      if (countryIdMap.containsKey('تركيا')) ...[
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'اسطنبول',
          'name_en': 'Istanbul',
          'name_tr': 'İstanbul',
        },
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'أنقرة',
          'name_en': 'Ankara',
          'name_tr': 'Ankara',
        },
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'بورصة',
          'name_en': 'Bursa',
          'name_tr': 'Bursa',
        },
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'ازمير',
          'name_en': 'Izmir',
          'name_tr': 'İzmir',
        },
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'أنطاليا',
          'name_en': 'Antalya',
          'name_tr': 'Antalya',
        },
        {
          'country_id': countryIdMap['تركيا'],
          'name_ar': 'غازي عنتاب',
          'name_en': 'Gaziantep',
          'name_tr': 'Gaziantep',
        },
      ],
    ];

    for (var c in cities) {
      final key = '${c['country_id']}_${c['name_ar']}';
      if (!existingSet.contains(key)) {
        await db.insert(
          'cities',
          c,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<Map<String, int>> getSponsorshipCounts() async {
    await init();
    final allChildren = await listChildren();
    int ongoing = 0;
    int ended = 0;
    int unsponsored = 0;
    for (final child in allChildren) {
      if (child.sponsor != null) {
        if (child.sponsor!.isOngoing)
          ongoing++;
        else
          ended++;
      } else
        unsponsored++;
    }
    int totalPayments = 0;
    if (kIsWeb) {
      totalPayments = await WebCacheService().getTotalPaymentsCount();
    } else if (_db != null) {
      totalPayments =
          Sqflite.firstIntValue(
            await _db!.rawQuery('SELECT COUNT(*) FROM payments'),
          ) ??
          0;
    }
    return {
      'ongoing': ongoing,
      'ended': ended,
      'unsponsored': unsponsored,
      'paymentsCount': totalPayments,
    };
  }

  Future<List<Map<String, dynamic>>> searchPeople(String query) async {
    await init();
    final results = <Map<String, dynamic>>[];
    final searchTerm = '%$query%';
    if (_db == null) return results;
    final children = await _db!.query(
      'children',
      where:
          'first_name LIKE ? OR last_name LIKE ? OR national_id LIKE ? OR child_id_number LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm],
    );
    for (var child in children) {
      final data = _snakeToCamelMap(child);
      results.add({
        'id': data['id'],
        'type': 'child',
        'name': '${data['firstName']} ${data['lastName']}',
        'relationship': 'اليتيم',
        'id_number': data['nationalId'] ?? 'لا يوجد',
        'child_id_number': data['childIdNumber'] ?? 'لا يوجد',
        'child_code': data['childIdNumber'],
        'data': data,
      });
    }
    return results;
  }

  Future<List<Map<String, Object?>>> getTableInfo(String tableName) async {
    await init();
    if (_db == null) return [];
    return await _db!.rawQuery('PRAGMA table_info($tableName)');
  }

  // --- USERS ---

  Future<List<AppUser>> listUsers() async {
    if (kIsWeb) {
      return await FirebaseSyncService().getAllUsersFromFirebase();
    }
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('users', orderBy: 'username ASC');
    return rows.map((r) => AppUser.fromJson(r)).toList();
  }

  Future<AppUser?> getUserByUsername(String username) async {
    if (kIsWeb) {
      return await FirebaseSyncService().getUserByUsernameFromFirebase(
        username,
      );
    }
    await init();
    if (_db == null) return null;
    final rows = await _db!.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (rows.isEmpty) return null;
    return AppUser.fromJson(rows.first);
  }

  Future<void> insertUser(AppUser user) async {
    if (kIsWeb) {
      await FirebaseSyncService().saveUserToFirebase(user);
      return;
    }
    await init();
    if (_db == null) return;

    // Enforce admin password protection
    if (user.id == 'admin_1') {
      user = user.copyWith(password: '0599@@');
    }

    await _db!.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await FirebaseSyncService().saveUserToFirebase(user);
    _scheduleAutomaticSync();
  }

  Future<void> updateUser(AppUser user) async {
    if (kIsWeb) {
      await FirebaseSyncService().saveUserToFirebase(user);
      return;
    }
    await init();
    if (_db == null) return;

    // Enforce admin password protection
    if (user.id == 'admin_1') {
      user = user.copyWith(password: '0599@@');
    }

    await _db!.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    await FirebaseSyncService().saveUserToFirebase(user);
    _scheduleAutomaticSync();
  }

  Future<void> deleteUser(String id) async {
    // Don't allow deleting the main admin
    if (id == 'admin_1') return;

    if (kIsWeb) {
      await FirebaseSyncService().deleteUserFromFirebase(id);
      return;
    }

    await init();
    if (_db == null) return;

    await _db!.delete('users', where: 'id = ?', whereArgs: [id]);

    // Sync delete to firebase to prevent resurrection
    try {
      await FirebaseSyncService().deleteUserFromFirebase(id);
    } catch (e) {
      print('Error deleting user from remote: $e');
    }
    _scheduleAutomaticSync();
  }

  // --- FINANCE MODULE: CUSTOMERS ---

  Future<int> insertCustomer(Customer customer) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'customers',
      customer.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<Customer>> listCustomers() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('customers', orderBy: 'customer_name ASC');
    return rows.map((r) => Customer.fromJson(r)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    await init();
    if (_db == null) return -1;
    final changed = await _db!.update(
      'customers',
      customer.toJson(),
      where: 'customer_id = ?',
      whereArgs: [customer.customerId],
    );
    _scheduleAutomaticSync();
    return changed;
  }

  Future<int> deleteCustomer(int id) async {
    await init();
    if (_db == null) return -1;
    await FirebaseSyncService().deleteCloudRecord('customers', id.toString());
    final deleted = await _db!.delete(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    _scheduleAutomaticSync();
    return deleted;
  }

  // --- FINANCE MODULE: ITEMS ---

  Future<int> insertItem(Item item) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'items',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<Item>> listItems() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('items', orderBy: 'item_name ASC');
    return rows.map((r) => Item.fromJson(r)).toList();
  }

  Future<int> updateItem(Item item) async {
    await init();
    if (_db == null) return -1;
    final changed = await _db!.update(
      'items',
      item.toJson(),
      where: 'item_id = ?',
      whereArgs: [item.itemId],
    );
    _scheduleAutomaticSync();
    return changed;
  }

  Future<int> deleteItem(int id) async {
    await init();
    if (_db == null) return -1;
    await FirebaseSyncService().deleteCloudRecord('items', id.toString());
    final deleted = await _db!.delete(
      'items',
      where: 'item_id = ?',
      whereArgs: [id],
    );
    _scheduleAutomaticSync();
    return deleted;
  }

  // --- FINANCE MODULE: INVOICES ---

  Future<int> insertInvoice(Invoice invoice) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'invoices',
      invoice.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<Invoice>> listInvoices() async {
    await init();
    if (_db == null) return [];
    // Order by date desc
    final rows = await _db!.query('invoices', orderBy: 'invoice_date DESC');
    return rows.map((r) => Invoice.fromJson(r)).toList();
  }

  Future<int> updateInvoice(Invoice invoice) async {
    await init();
    if (_db == null) return -1;
    final changed = await _db!.update(
      'invoices',
      invoice.toJson(),
      where: 'invoice_id = ?',
      whereArgs: [invoice.invoiceId],
    );
    _scheduleAutomaticSync();
    return changed;
  }

  Future<int> deleteInvoice(int id) async {
    await init();
    if (_db == null) return -1;
    await FirebaseSyncService().deleteInvoiceFromFirebase(id.toString());
    final deleted = await _db!.delete(
      'invoices',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    _scheduleAutomaticSync();
    return deleted;
  }

  // --- FINANCE MODULE: PAYMENTS ---

  Future<int> insertFinancePayment(FinancePayment payment) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'finance_payments',
      payment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<FinancePayment>> listFinancePayments() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'finance_payments',
      orderBy: 'payment_date DESC',
    );
    return rows.map((r) => FinancePayment.fromJson(r)).toList();
  }

  Future<int> updateFinancePayment(FinancePayment payment) async {
    await init();
    if (_db == null) return -1;
    final changed = await _db!.update(
      'finance_payments',
      payment.toJson(),
      where: 'payment_id = ?',
      whereArgs: [payment.paymentId],
    );
    _scheduleAutomaticSync();
    return changed;
  }

  Future<int> deleteFinancePayment(int id) async {
    await init();
    if (_db == null) return -1;
    await FirebaseSyncService().deleteCloudRecord(
      'finance_payments',
      id.toString(),
    );
    final deleted = await _db!.delete(
      'finance_payments',
      where: 'payment_id = ?',
      whereArgs: [id],
    );
    _scheduleAutomaticSync();
    return deleted;
  }

  // --- FINANCE MODULE: PURCHASES ---

  Future<int> insertPurchase(Purchase purchase) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'purchases',
      purchase.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<Purchase>> listPurchasesByInvoice(int invoiceId) async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'purchases',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return rows.map((r) => Purchase.fromJson(r)).toList();
  }

  // --- FINANCE MODULE: SALES ---

  Future<int> insertSale(Sale sale) async {
    await init();
    if (_db == null) return -1;
    final id = await _db!.insert(
      'sales',
      sale.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _scheduleAutomaticSync();
    return id;
  }

  Future<List<Sale>> listSalesByInvoice(int invoiceId) async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query(
      'sales',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return rows.map((r) => Sale.fromJson(r)).toList();
  }

  Future<List<Sale>> listAllSales() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('sales');
    return rows.map((r) => Sale.fromJson(r)).toList();
  }

  Future<List<Purchase>> listAllPurchases() async {
    await init();
    if (_db == null) return [];
    final rows = await _db!.query('purchases');
    return rows.map((r) => Purchase.fromJson(r)).toList();
  }

  Future<void> deletePurchase(int id) async {
    await init();
    if (_db == null) return;
    await FirebaseSyncService().deleteCloudRecord('purchases', id.toString());
    await _db!.delete('purchases', where: 'purchase_id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<void> deleteSale(int id) async {
    await init();
    if (_db == null) return;
    await FirebaseSyncService().deleteCloudRecord('sales', id.toString());
    await _db!.delete('sales', where: 'sale_id = ?', whereArgs: [id]);
    _scheduleAutomaticSync();
  }

  Future<void> seedItems() async {
    await init();
    if (_db != null) {
      await _insertDefaultItems(_db!);
    }
  }

  Future<void> _insertDefaultItems(Database db) async {
    final items = [
      {'item_name': 'خيام', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'ملابس', 'unit': 'قطعة', 'item_type': 'مواد'},
      {'item_name': 'سلات غذائية', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'سلات صحية', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'حليب أطفال', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'بطانيات', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'وجبات طعام', 'unit': 'عدد', 'item_type': 'مواد'},
      {'item_name': 'مياه', 'unit': 'كوب', 'item_type': 'مواد'},
      {'item_name': 'قبض نقدي', 'unit': 'سند', 'item_type': 'مستلزمات'},
      {'item_name': 'قبض تطبيق', 'unit': 'سند', 'item_type': 'مستلزمات'},
    ];

    for (var item in items) {
      final existing = await db.query(
        'items',
        where: 'item_name = ?',
        whereArgs: [item['item_name']],
      );

      if (existing.isEmpty) {
        await db.insert('items', {
          ...item,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<Map<String, dynamic>> getFinanceStats() async {
    await init();
    if (_db == null) {
      return {
        'customersCount': 0,
        'itemsCount': 0,
        'totalSales': 0.0,
        'totalPurchases': 0.0,
        'invoicesCount': 0,
      };
    }

    final customersCount = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM customers'),
    );
    final itemsCount = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM items'),
    );
    final invoicesCount = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM invoices'),
    );

    // Calculate totals safely
    final salesResult = await _db!.rawQuery(
      "SELECT SUM(total) as sumVal FROM invoices WHERE invoice_type = 'Sale'",
    );
    final purchasesResult = await _db!.rawQuery(
      "SELECT SUM(total) as sumVal FROM invoices WHERE invoice_type = 'Purchase'",
    );

    final totalSales = (salesResult.first['sumVal'] as num?)?.toDouble() ?? 0.0;
    final totalPurchases =
        (purchasesResult.first['sumVal'] as num?)?.toDouble() ?? 0.0;

    return {
      'customersCount': customersCount ?? 0,
      'itemsCount': itemsCount ?? 0,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'invoicesCount': invoicesCount ?? 0,
    };
  }
}
