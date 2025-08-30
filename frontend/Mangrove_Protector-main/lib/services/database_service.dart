import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mangrove_protector/models/user_model.dart';
import 'package:mangrove_protector/models/tree_model.dart';
import 'package:mangrove_protector/models/community_model.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mangrove_protector.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        nickname TEXT NOT NULL,
        communityId TEXT NOT NULL,
        profileImage TEXT,
        isAdmin INTEGER NOT NULL DEFAULT 0,
        points INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Communities table
    await db.execute('''
      CREATE TABLE communities(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        location TEXT,
        adminIds TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Trees table
    await db.execute('''
      CREATE TABLE trees(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        communityId TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        imageUrl TEXT,
        status TEXT NOT NULL,
        plantedDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isVerified INTEGER NOT NULL DEFAULT 0,
        verifiedBy TEXT,
        verifiedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (communityId) REFERENCES communities (id)
      )
    ''');

    // Maintenance table
    await db.execute('''
      CREATE TABLE maintenance(
        id TEXT PRIMARY KEY,
        treeId TEXT NOT NULL,
        userId TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT,
        date TEXT NOT NULL,
        isVerified INTEGER NOT NULL DEFAULT 0,
        verifiedBy TEXT,
        verifiedAt TEXT,
        FOREIGN KEY (treeId) REFERENCES trees (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Rewards table
    await db.execute('''
      CREATE TABLE rewards(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        communityId TEXT NOT NULL,
        points INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        relatedEntityId TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        approvedBy TEXT,
        approvedAt TEXT,
        redeemedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (communityId) REFERENCES communities (id)
      )
    ''');

    // Illegal Activities table
    await db.execute('''
      CREATE TABLE illegal_activities(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        communityId TEXT NOT NULL,
        activityType TEXT NOT NULL,
        description TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        imageUrl TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        reportedDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isVerified INTEGER NOT NULL DEFAULT 0,
        verifiedBy TEXT,
        verifiedAt TEXT,
        adminNotes TEXT,
        resolutionNotes TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (communityId) REFERENCES communities (id)
      )
    ''');

    // Reward Items table
    await db.execute('''
      CREATE TABLE reward_items(
        id TEXT PRIMARY KEY,
        communityId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        pointsCost INTEGER NOT NULL,
        availableQuantity INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (communityId) REFERENCES communities (id)
      )
    ''');

    // Sync Status table for offline sync
    await db.execute('''
      CREATE TABLE sync_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add illegal_activities table
      await db.execute('''
        CREATE TABLE illegal_activities(
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          communityId TEXT NOT NULL,
          activityType TEXT NOT NULL,
          description TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          imageUrl TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          reportedDate TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isVerified INTEGER NOT NULL DEFAULT 0,
          verifiedBy TEXT,
          verifiedAt TEXT,
          adminNotes TEXT,
          resolutionNotes TEXT,
          FOREIGN KEY (userId) REFERENCES users (id),
          FOREIGN KEY (communityId) REFERENCES communities (id)
        )
      ''');

      // Add sync_status table
      await db.execute('''
        CREATE TABLE sync_status(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entityType TEXT NOT NULL,
          entityId TEXT NOT NULL,
          operation TEXT NOT NULL,
          data TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  // User methods
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<List<User>> getUsersByCommunity(String communityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'communityId = ?',
      whereArgs: [communityId],
    );

    return List.generate(maps.length, (i) {
      return User.fromJson(maps[i]);
    });
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Community methods
  Future<void> insertCommunity(Community community) async {
    final db = await database;
    await db.insert(
      'communities',
      {
        ...community.toJson(),
        'adminIds': community.adminIds.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Community?> getCommunity(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'communities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    final Map<String, dynamic> data = {...maps.first};
    data['adminIds'] = data['adminIds'] != null && data['adminIds'].isNotEmpty
        ? (data['adminIds'] as String).split(',')
        : [];
    
    return Community.fromJson(data);
  }

  Future<List<Community>> getAllCommunities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('communities');

    return List.generate(maps.length, (i) {
      final Map<String, dynamic> data = {...maps[i]};
      data['adminIds'] = data['adminIds'] != null && data['adminIds'].isNotEmpty
          ? (data['adminIds'] as String).split(',')
          : [];
      
      return Community.fromJson(data);
    });
  }

  Future<void> updateCommunity(Community community) async {
    final db = await database;
    await db.update(
      'communities',
      {
        ...community.toJson(),
        'adminIds': community.adminIds.join(','),
      },
      where: 'id = ?',
      whereArgs: [community.id],
    );
  }

  // Tree methods
  Future<void> insertTree(Tree tree) async {
    final db = await database;
    await db.insert(
      'trees',
      tree.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert maintenance records
    for (var maintenance in tree.maintenanceHistory) {
      await insertMaintenance(maintenance);
    }
  }

  Future<Tree?> getTree(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trees',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    // Get maintenance records for this tree
    final List<Maintenance> maintenanceHistory = await getMaintenanceByTree(id);
    
    final Map<String, dynamic> treeData = {...maps.first};
    treeData['maintenanceHistory'] = maintenanceHistory;
    
    return Tree.fromJson(treeData);
  }

  Future<List<Tree>> getTreesByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trees',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return Future.wait(maps.map((map) async {
      final String treeId = map['id'];
      final List<Maintenance> maintenanceHistory = await getMaintenanceByTree(treeId);
      
      final Map<String, dynamic> treeData = {...map};
      treeData['maintenanceHistory'] = maintenanceHistory;
      
      return Tree.fromJson(treeData);
    }).toList());
  }

  Future<List<Tree>> getTreesByCommunity(String communityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trees',
      where: 'communityId = ?',
      whereArgs: [communityId],
    );

    return Future.wait(maps.map((map) async {
      final String treeId = map['id'];
      final List<Maintenance> maintenanceHistory = await getMaintenanceByTree(treeId);
      
      final Map<String, dynamic> treeData = {...map};
      treeData['maintenanceHistory'] = maintenanceHistory;
      
      return Tree.fromJson(treeData);
    }).toList());
  }

  Future<void> updateTree(Tree tree) async {
    final db = await database;
    await db.update(
      'trees',
      tree.toJson(),
      where: 'id = ?',
      whereArgs: [tree.id],
    );

    // Update maintenance records
    for (var maintenance in tree.maintenanceHistory) {
      await insertMaintenance(maintenance);
    }
  }

  // Maintenance methods
  Future<void> insertMaintenance(Maintenance maintenance) async {
    final db = await database;
    await db.insert(
      'maintenance',
      maintenance.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Maintenance>> getMaintenanceByTree(String treeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maintenance',
      where: 'treeId = ?',
      whereArgs: [treeId],
    );

    return List.generate(maps.length, (i) {
      return Maintenance.fromJson(maps[i]);
    });
  }

  // Reward methods
  Future<void> insertReward(Reward reward) async {
    final db = await database;
    await db.insert(
      'rewards',
      reward.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Reward>> getRewardsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Reward.fromJson(maps[i]);
    });
  }

  Future<List<Reward>> getRewardsByCommunity(String communityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'communityId = ?',
      whereArgs: [communityId],
    );

    return List.generate(maps.length, (i) {
      return Reward.fromJson(maps[i]);
    });
  }

  Future<void> updateReward(Reward reward) async {
    final db = await database;
    await db.update(
      'rewards',
      reward.toJson(),
      where: 'id = ?',
      whereArgs: [reward.id],
    );
  }

  // Reward Item methods
  Future<void> insertRewardItem(RewardItem item) async {
    final db = await database;
    await db.insert(
      'reward_items',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RewardItem>> getRewardItemsByCommunity(String communityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reward_items',
      where: 'communityId = ? AND isActive = 1',
      whereArgs: [communityId],
    );

    return List.generate(maps.length, (i) {
      return RewardItem.fromJson(maps[i]);
    });
  }

  Future<void> updateRewardItem(RewardItem item) async {
    final db = await database;
    await db.update(
      'reward_items',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Sync methods
  Future<void> addToSyncQueue(String entityType, String entityId, String operation, String data) async {
    final db = await database;
    await db.insert(
      'sync_status',
      {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'data': data,
        'synced': 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_status',
      where: 'synced = 0',
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_status',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Illegal Activity methods
  Future<void> insertIllegalActivity(IllegalActivity activity) async {
    final db = await database;
    await db.insert(
      'illegal_activities',
      activity.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<IllegalActivity?> getIllegalActivity(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'illegal_activities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return IllegalActivity.fromJson(maps.first);
  }

  Future<List<IllegalActivity>> getAllIllegalActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('illegal_activities');

    return List.generate(maps.length, (i) {
      return IllegalActivity.fromJson(maps[i]);
    });
  }

  Future<List<IllegalActivity>> getIllegalActivitiesByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'illegal_activities',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return IllegalActivity.fromJson(maps[i]);
    });
  }

  Future<List<IllegalActivity>> getIllegalActivitiesByCommunity(String communityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'illegal_activities',
      where: 'communityId = ?',
      whereArgs: [communityId],
    );

    return List.generate(maps.length, (i) {
      return IllegalActivity.fromJson(maps[i]);
    });
  }

  Future<void> updateIllegalActivity(IllegalActivity activity) async {
    final db = await database;
    await db.update(
      'illegal_activities',
      activity.toJson(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }
}

