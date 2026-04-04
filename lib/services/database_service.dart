import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tree_model.dart';
import 'sync_service.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'geocamera_v2.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            password TEXT,
            role TEXT,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE trees (
            treeId TEXT PRIMARY KEY,
            userId TEXT,
            donorName TEXT,
            plantName TEXT,
            areaName TEXT,
            remarks TEXT,
            latitude REAL,
            longitude REAL,
            imagePath TEXT,
            dateTime TEXT,
            createdBy TEXT,
            syncStatus INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE tree_updates (
            updateId TEXT PRIMARY KEY,
            treeId TEXT,
            userId TEXT,
            imagePath TEXT,
            height TEXT,
            condition TEXT,
            remarks TEXT,
            latitude REAL,
            longitude REAL,
            dateTime TEXT,
            updatedBy TEXT,
            syncStatus INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add syncStatus column if upgrading from version 1
          try {
            await db.execute('ALTER TABLE trees ADD COLUMN syncStatus INTEGER DEFAULT 0');
          } catch (e) {
            // Column might already exist
          }
          try {
            await db.execute('ALTER TABLE tree_updates ADD COLUMN syncStatus INTEGER DEFAULT 0');
          } catch (e) {
            // Column might already exist
          }
        }
        if (oldVersion < 3) {
          // Ensure syncStatus exists for version 3
          try {
            await db.execute('ALTER TABLE trees ADD COLUMN syncStatus INTEGER DEFAULT 0');
          } catch (e) {
            // Column might already exist
          }
          try {
            await db.execute('ALTER TABLE tree_updates ADD COLUMN syncStatus INTEGER DEFAULT 0');
          } catch (e) {
            // Column might already exist
          }
        }
      },
    );
  }

  // --- Users ---
  static Future<void> insertUser(AppUser user) async {
    final database = await db;
    await database.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<AppUser?> getUserByEmail(String email) async {
    final database = await db;
    final results = await database.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (results.isEmpty) return null;
    return AppUser.fromMap(results.first);
  }

  // --- Trees ---
  static Future<void> insertTree(TreeRecord tree) async {
    final database = await db;
    await database.insert('trees', tree.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.queueForSync(SyncItem(id: tree.treeId, type: 'tree', data: tree.toMap(), timestamp: DateTime.now()));
  }

  static Future<void> updateTree(String treeId, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update('trees', updates, where: 'treeId = ?', whereArgs: [treeId]);
  }

  static Future<void> insertTreeUpdate(TreeUpdate update) async {
    final database = await db;
    await database.insert('tree_updates', update.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.queueForSync(SyncItem(id: update.updateId, type: 'update', data: update.toMap(), timestamp: DateTime.now()));
  }

  static Future<void> deleteTree(String treeId) async {
    final database = await db;
    await database.delete('trees', where: 'treeId = ?', whereArgs: [treeId]);
    await database.delete('tree_updates', where: 'treeId = ?', whereArgs: [treeId]);
  }

  static Future<List<TreeRecord>> getTrees() async {
    final database = await db;
    final treeResults = await database.query('trees', orderBy: 'dateTime DESC');
    
    // For a cleaner look, get all updates and match them manually if there are many trees.
    // To limit queries, we fetch all updates and group them, rather than querying in a loop if data gets big.
    final updateResults = await database.query('tree_updates', orderBy: 'dateTime ASC');
    
    final updatesByTree = <String, List<TreeUpdate>>{};
    for (var uMap in updateResults) {
      final u = TreeUpdate.fromMap(uMap);
      if (!updatesByTree.containsKey(u.treeId)) updatesByTree[u.treeId] = [];
      updatesByTree[u.treeId]!.add(u);
    }

    final trees = <TreeRecord>[];
    for (var tMap in treeResults) {
      final t = TreeRecord.fromMap(tMap, updates: updatesByTree[tMap['treeId']]);
      trees.add(t);
    }
    return trees;
  }

  static Future<TreeRecord?> getTreeById(String id) async {
    final database = await db;
    final results = await database.query('trees', where: 'treeId = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    
    // Get updates for this tree specifically
    final updateResults = await database.query('tree_updates', where: 'treeId = ?', whereArgs: [id], orderBy: 'dateTime ASC');
    final updates = updateResults.map((uMap) => TreeUpdate.fromMap(uMap)).toList();
    
    return TreeRecord.fromMap(results.first, updates: updates);
  }

  static Future<Map<String, int>> getStats() async {
    final database = await db;
    final treeCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM trees')) ?? 0;
    final updateCount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM tree_updates')) ?? 0;
    
    // Today entries
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayCount = Sqflite.firstIntValue(await database.rawQuery("SELECT COUNT(*) FROM trees WHERE dateTime LIKE ?", ["$todayStr%"])) ?? 0;
    
    return {
      'totalTrees': treeCount,
      'totalUpdates': updateCount,
      'todayEntries': todayCount,
    };
  }
}
