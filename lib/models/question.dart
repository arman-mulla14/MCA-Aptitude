class Question {
  final String questionId;
  final String assessmentId;
  final String round; // 'gd' | 'technical'
  final String questionText;
  final List<String> options;
  final String correctAnswer; // 'A', 'B', 'C', 'D' or option text
  final int marks;
  final int order;
  final bool isActive;

  Question({
    required this.questionId,
    required this.assessmentId,
    required this.round,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.marks = 1,
    this.order = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'assessmentId': assessmentId,
      'round': round,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'marks': marks,
      'order': order,
      'isActive': isActive,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      questionId: id.isNotEmpty ? id : (map['questionId'] ?? ''),
      assessmentId: map['assessmentId'] ?? '',
      round: map['round'] ?? 'gd',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 'A',
      marks: (map['marks'] as num?)?.toInt() ?? 1,
      order: (map['order'] as num?)?.toInt() ?? 1,
      isActive: map['isActive'] ?? true,
    );
  }

  Question copyWith({
    String? questionId,
    String? assessmentId,
    String? round,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    int? marks,
    int? order,
    bool? isActive,
  }) {
    return Question(
      questionId: questionId ?? this.questionId,
      assessmentId: assessmentId ?? this.assessmentId,
      round: round ?? this.round,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      marks: marks ?? this.marks,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}
