

class HistoryItem {
  String? id;
  final String fileName;
  final String filePath;
  DateTime timestamp;
  bool isSuccess;

  HistoryItem({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.timestamp,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() {
    return {
      if(id != null) 'id':id,
      'fileName': fileName,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSuccess: json['isSuccess'] as bool,
    );
  }
}
