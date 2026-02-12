import 'dart:convert';

class SessionRecord {
  final int index;
  final String type;
  final DateTime timestamp;
  final String tyreState;

  SessionRecord({
    required this.index, 
    required this.type, 
    required this.timestamp,
    required this.tyreState
  });

  // Serialization: Object -> Map -> JSON String
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'tyreState' : tyreState
    };
  }

  // Deserialization: JSON String -> Map -> Object
  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      index: map['index'] as int,
      type: map['type'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      tyreState: map['tyreState'] as String
      // TO DO:
      // cold pressures
      // hot pressures
      // left T/B pill
      // right T/B pill

    );
  }

  // A helper to make the SharedPreferences code cleaner
  String toJson() => json.encode(toMap());
  
  factory SessionRecord.fromJson(String source) => 
      SessionRecord.fromMap(json.decode(source) as Map<String, dynamic>);
}