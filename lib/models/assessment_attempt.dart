class AssessmentAttempt {
  final String attemptId;
  final String studentId;
  final String grnNumber;
  final String round;
  final String status; // 'IN_PROGRESS' | 'COMPLETED' | 'TERMINATED' | 'ABANDONED'
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime lastHeartbeatAt;
  final String sessionId;
  final int violationCount;
  final int obtainedMarks;
  final int totalMarks;
  final bool isPassed;

  AssessmentAttempt({
    required this.attemptId,
    required this.studentId,
    required this.grnNumber,
    required this.round,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.lastHeartbeatAt,
    required this.sessionId,
    this.violationCount = 0,
    this.obtainedMarks = 0,
    this.totalMarks = 0,
    this.isPassed = false,
  });

  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isActive => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isTerminated => status == 'TERMINATED';
  bool get isAbandoned => status == 'ABANDONED';

  bool isExpired(DateTime now) => now.isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'studentId': studentId,
      'grnNumber': grnNumber,
      'round': round,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'lastHeartbeatAt': lastHeartbeatAt.toIso8601String(),
      'sessionId': sessionId,
      'violationCount': violationCount,
      'obtainedMarks': obtainedMarks,
      'totalMarks': totalMarks,
      'isPassed': isPassed,
    };
  }

  factory AssessmentAttempt.fromMap(Map<String, dynamic> map, String docId) {
    return AssessmentAttempt(
      attemptId: docId.isNotEmpty ? docId : (map['attemptId'] ?? ''),
      studentId: map['studentId'] ?? '',
      grnNumber: map['grnNumber'] ?? '',
      round: map['round'] ?? '',
      status: map['status'] ?? 'IN_PROGRESS',
      startedAt: DateTime.tryParse(map['startedAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(minutes: 30)),
      lastHeartbeatAt: DateTime.tryParse(map['lastHeartbeatAt'] ?? '') ?? DateTime.now(),
      sessionId: map['sessionId'] ?? '',
      violationCount: (map['violationCount'] as num?)?.toInt() ?? 0,
      obtainedMarks: (map['obtainedMarks'] as num?)?.toInt() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toInt() ?? 0,
      isPassed: map['isPassed'] ?? false,
    );
  }

  AssessmentAttempt copyWith({
    String? status,
    DateTime? lastHeartbeatAt,
    int? violationCount,
    int? obtainedMarks,
    int? totalMarks,
    bool? isPassed,
  }) {
    return AssessmentAttempt(
      attemptId: attemptId,
      studentId: studentId,
      grnNumber: grnNumber,
      round: round,
      status: status ?? this.status,
      startedAt: startedAt,
      expiresAt: expiresAt,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      sessionId: sessionId,
      violationCount: violationCount ?? this.violationCount,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      isPassed: isPassed ?? this.isPassed,
    );
  }
}
