class AssessmentViolation {
  final String violationId;
  final String attemptId;
  final String studentId;
  final String grnNumber;
  final String eventType; // 'NEW_TAB' | 'WINDOW_BLUR' | 'FULLSCREEN_EXIT' | 'WINDOW_MINIMIZED' | 'WINDOW_RESIZED' | 'SMALL_VIEWPORT' | 'SPLIT_SCREEN' | 'BACK_BUTTON'
  final DateTime timestamp;
  final String details;

  AssessmentViolation({
    required this.violationId,
    required this.attemptId,
    required this.studentId,
    required this.grnNumber,
    required this.eventType,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'violationId': violationId,
      'attemptId': attemptId,
      'studentId': studentId,
      'grnNumber': grnNumber,
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }

  factory AssessmentViolation.fromMap(Map<String, dynamic> map, [String docId = '']) {
    return AssessmentViolation(
      violationId: docId.isNotEmpty ? docId : (map['violationId'] ?? ''),
      attemptId: map['attemptId'] ?? '',
      studentId: map['studentId'] ?? '',
      grnNumber: map['grnNumber'] ?? '',
      eventType: map['eventType'] ?? 'UNKNOWN',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      details: map['details'] ?? '',
    );
  }
}
