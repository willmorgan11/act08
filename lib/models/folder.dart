class Folder {
  final int? id;
  final String folderName;
  final String timestamp;

  Folder({
    this.id,
    required this.folderName,
    required this.timestamp,
  });

  // Convert Folder object to Map for database operations
  Map<String, dynamic> toMap() => {
    'id': id,
    'folder_name': folderName,
    'timestamp': timestamp,
  };

  // Create Folder object from Map (database query result)
  factory Folder.fromMap(Map<String, dynamic> map) => Folder(
    id: map['id'],
    folderName: map['folder_name'],
    timestamp: map['timestamp'],
  );

  // Create a copy with modified fields
  Folder copyWith({int? id, String? folderName, String? timestamp}) => Folder(
    id: id ?? this.id,
    folderName: folderName ?? this.folderName,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  String toString() =>
      'Folder{id: $id, folderName: $folderName, timestamp: $timestamp}';
}