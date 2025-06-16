class SessionModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String tableId;

  SessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.tableId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'tableId': tableId,
    };
  }

  factory SessionModel.fromFirestore(String id, Map<String, dynamic> map) {
    return SessionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      tableId: map['tableId'] ?? '',
    );
  }

  SessionModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? tableId,
  }) {
    return SessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      tableId: tableId ?? this.tableId,
    );
  }
}
