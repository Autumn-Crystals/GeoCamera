// Tree data models
class AppUser {
  final String id; // Represents uid
  final String name;
  final String email;
  final String password;
  final String role;
  final String createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'worker',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'email': email,
    'password': password, 'role': role, 'createdAt': createdAt,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'], name: map['name'], email: map['email'],
    password: map['password'], role: map['role'] ?? 'worker', createdAt: map['createdAt'],
  );
}

class TreeUpdate {
  final String updateId;
  final String treeId; // Foreign key
  final String userId; // User who made the update
  final String imagePath; // Local file path or Firebase Storage URL
  final String height;
  final String condition;
  final String remarks;
  final double latitude;
  final double longitude;
  final String dateTime;
  final String updatedBy; // Worker name cache
  final int syncStatus; // 0=Pending, 1=Synced

  TreeUpdate({
    required this.updateId, required this.treeId, required this.userId,
    required this.imagePath, this.height = '',
    this.condition = 'Good', this.remarks = '', required this.latitude,
    required this.longitude, required this.dateTime, required this.updatedBy,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
    'updateId': updateId, 'treeId': treeId, 'userId': userId,
    'imagePath': imagePath, 'height': height,
    'condition': condition, 'remarks': remarks, 'latitude': latitude,
    'longitude': longitude, 'dateTime': dateTime, 'updatedBy': updatedBy,
    'syncStatus': syncStatus,
  };

  factory TreeUpdate.fromMap(Map<String, dynamic> map) => TreeUpdate(
    updateId: map['updateId'], treeId: map['treeId'], userId: map['userId'] ?? '',
    imagePath: map['imagePath'] ?? '',
    height: map['height'] ?? '', condition: map['condition'] ?? 'Good',
    remarks: map['remarks'] ?? '', latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    dateTime: map['dateTime'], updatedBy: map['updatedBy'] ?? '',
    syncStatus: map['syncStatus'] ?? 0,
  );
}

class TreeRecord {
  final String treeId;
  final String userId; // User who planted the tree
  final String donorName;
  final String plantName;
  final String? areaName;
  final String? remarks;
  final double latitude;
  final double longitude;
  final String imagePath; // Local file path or Firebase Storage URL
  final String dateTime;
  final String createdBy; // Worker name cache
  final List<TreeUpdate> updates; // Populated logically
  final int syncStatus; // 0=Pending, 1=Synced

  TreeRecord({
    required this.treeId, required this.userId, required this.donorName,
    required this.plantName, this.areaName, this.remarks, 
    required this.latitude, required this.longitude,
    required this.imagePath, required this.dateTime, required this.createdBy,
    this.syncStatus = 0,
    List<TreeUpdate>? updates,
  }) : updates = updates ?? [];

  // Used for saving just the record to SQLite
  Map<String, dynamic> toMap() => {
    'treeId': treeId, 'userId': userId, 'donorName': donorName,
    'plantName': plantName, 'areaName': areaName, 'remarks': remarks,
    'latitude': latitude, 'longitude': longitude,
    'imagePath': imagePath, 'dateTime': dateTime, 'createdBy': createdBy,
    'syncStatus': syncStatus,
  };

  factory TreeRecord.fromMap(Map<String, dynamic> map, {List<TreeUpdate>? updates}) => TreeRecord(
    treeId: map['treeId'], userId: map['userId'] ?? '',
    donorName: map['donorName'], plantName: map['plantName'],
    areaName: map['areaName'], remarks: map['remarks'],
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    imagePath: map['imagePath'] ?? '', dateTime: map['dateTime'],
    createdBy: map['createdBy'] ?? '',
    syncStatus: map['syncStatus'] ?? 0,
    updates: updates ?? [],
  );

  TreeRecord copyWithUpdates(List<TreeUpdate> newUpdates) {
    return TreeRecord(
      treeId: treeId, userId: userId, donorName: donorName,
      plantName: plantName, areaName: areaName, remarks: remarks,
      latitude: latitude, longitude: longitude,
      imagePath: imagePath, dateTime: dateTime, createdBy: createdBy,
      syncStatus: syncStatus,
      updates: newUpdates,
    );
  }
}
