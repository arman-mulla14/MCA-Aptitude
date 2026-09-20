class Assessment {
  final String assessmentId;
  final String title;
  final String round; // 'gd' or 'technical' or custom round key
  final int passingMarks;
  final int totalMarks;
  final bool isActive;
  final List<String> registeredStudentGrns; // List of GRN Numbers authorized for this assessment
  final DateTime createdAt;

  Assessment({
    required this.assessmentId,
    required this.title,
    required this.round,
    required this.passingMarks,
    this.totalMarks = 0,
    this.isActive = true,
    List<String>? registeredStudentGrns,
    DateTime? createdAt,
  })  : registeredStudentGrns = registeredStudentGrns ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'assessmentId': assessmentId,
      'title': title,
      'round': round,
      'passingMarks': passingMarks,
      'totalMarks': totalMarks,
      'isActive': isActive,
      'registeredStudentGrns': registeredStudentGrns,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Assessment.fromMap(Map<String, dynamic> map, String id) {
    return Assessment(
      assessmentId: id.isNotEmpty ? id : (map['assessmentId'] ?? ''),
      title: map['title'] ?? '',
      round: map['round'] ?? 'gd',
      passingMarks: (map['passingMarks'] as num?)?.toInt() ?? 3,
      totalMarks: (map['totalMarks'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      registeredStudentGrns: map['registeredStudentGrns'] != null
          ? List<String>.from(map['registeredStudentGrns'])
          : [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Assessment copyWith({
    String? assessmentId,
    String? title,
    String? round,
    int? passingMarks,
    int? totalMarks,
    bool? isActive,
    List<String>? registeredStudentGrns,
    DateTime? createdAt,
  }) {
    return Assessment(
      assessmentId: assessmentId ?? this.assessmentId,
      title: title ?? this.title,
      round: round ?? this.round,
      passingMarks: passingMarks ?? this.passingMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      isActive: isActive ?? this.isActive,
      registeredStudentGrns: registeredStudentGrns ?? this.registeredStudentGrns,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

