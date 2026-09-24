class AssessmentResult {
  final String resultId;
  final String studentId;
  final String grnNumber;
  final String studentName;
  final String assessmentId;
  final String round; // 'gd' | 'technical'
  final int obtainedMarks;
  final int totalMarks;
  final int passingMarks;
  final String status; // 'PASSED' | 'FAILED'
  final Map<String, String> answersMap; // questionId -> selectedAnswer ('A'/'B'/'C'/'D')
  final DateTime submittedAt;

  AssessmentResult({
    required this.resultId,
    required this.studentId,
    required this.grnNumber,
    this.studentName = '',
    required this.assessmentId,
    required this.round,
    required this.obtainedMarks,
    required this.totalMarks,
    required this.passingMarks,
    required this.status,
    this.answersMap = const {},
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  bool get isPassed => status.toUpperCase() == 'PASS' || status.toUpperCase() == 'PASSED';

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'studentId': studentId,
      'grnNumber': grnNumber,
      'studentName': studentName,
      'assessmentId': assessmentId,
      'round': round,
      'obtainedMarks': obtainedMarks,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'status': status,
      'answersMap': answersMap,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory AssessmentResult.fromMap(Map<String, dynamic> map, String id) {
    Map<String, String> parsedAnswers = {};
    if (map['answersMap'] != null && map['answersMap'] is Map) {
      (map['answersMap'] as Map).forEach((k, v) {
        parsedAnswers[k.toString()] = v.toString();
      });
    }

    return AssessmentResult(
      resultId: id.isNotEmpty ? id : (map['resultId'] ?? ''),
      studentId: map['studentId'] ?? '',
      grnNumber: map['grnNumber'] ?? '',
      studentName: map['studentName'] ?? '',
      assessmentId: map['assessmentId'] ?? '',
      round: map['round'] ?? 'gd',
      obtainedMarks: (map['obtainedMarks'] as num?)?.toInt() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toInt() ?? 0,
      passingMarks: (map['passingMarks'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'FAILED',
      answersMap: parsedAnswers,
      submittedAt: map['submittedAt'] != null
          ? DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
