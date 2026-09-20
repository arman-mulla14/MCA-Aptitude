import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/student.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/assessment_attempt.dart';
import '../models/assessment_violation.dart';
import '../models/security_policy.dart';
import '../core/constants/app_constants.dart';

class DataService extends ChangeNotifier {
  final List<Student> _students = [];
  final List<Assessment> _assessments = [];
  final List<Question> _questions = [];
  final List<AssessmentResult> _results = [];
  final List<AssessmentAttempt> _attempts = [];
  final List<AssessmentViolation> _violations = [];
  SecurityPolicy _securityPolicy = const SecurityPolicy();

  StreamSubscription<QuerySnapshot>? _attemptsSub;
  StreamSubscription<QuerySnapshot>? _violationsSub;
  StreamSubscription<QuerySnapshot>? _studentsSub;
  StreamSubscription<QuerySnapshot>? _resultsSub;

  bool _isFirestoreActive = false;
  bool _isLoading = false;

  bool get isFirestoreActive => _isFirestoreActive;
  bool get isLoading => _isLoading;

  List<Student> get students => List.unmodifiable(_students);
  List<Assessment> get assessments => List.unmodifiable(_assessments);
  List<Question> get questions => List.unmodifiable(_questions);
  List<AssessmentResult> get results => List.unmodifiable(_results);
  List<AssessmentAttempt> get attempts => List.unmodifiable(_attempts);
  List<AssessmentViolation> get violations => List.unmodifiable(_violations);
  SecurityPolicy get securityPolicy => _securityPolicy;

  DataService() {
    _initializeData();
  }

  @override
  void dispose() {
    _attemptsSub?.cancel();
    _violationsSub?.cancel();
    _studentsSub?.cancel();
    _resultsSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    // 1. First load from local storage cache so all imported student records remain intact
    await _loadFromLocalStorage();

    // 2. Sync with Cloud Firestore without erasing existing student records
    try {
      _isFirestoreActive = true;
      await _loadFromFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Firestore init fallback to local: $e');
      }
      _isFirestoreActive = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- LOCAL PERSISTENCE & SEED DATA ---

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final studentsJson = prefs.getString('mca_students');
    final assessmentsJson = prefs.getString('mca_assessments');
    final questionsJson = prefs.getString('mca_questions');
    final resultsJson = prefs.getString('mca_results');
    final attemptsJson = prefs.getString('mca_attempts');
    final violationsJson = prefs.getString('mca_violations');

    if (studentsJson != null) {
      final List decoded = jsonDecode(studentsJson);
      for (var item in decoded) {
        final s = Student.fromMap(item, item['studentId'] ?? '');
        final existingIdx = _students.indexWhere((x) => x.grnNumber.toUpperCase() == s.grnNumber.toUpperCase());
        if (existingIdx != -1) {
          _students[existingIdx] = s;
        } else {
          _students.add(s);
        }
      }
    } else {
      _seedDefaultStudents();
    }

    if (assessmentsJson != null) {
      final List decoded = jsonDecode(assessmentsJson);
      _assessments.clear();
      _assessments.addAll(decoded.map((item) => Assessment.fromMap(item, item['assessmentId'] ?? '')));
    } else {
      _seedDefaultAssessments();
    }

    if (questionsJson != null) {
      final List decoded = jsonDecode(questionsJson);
      _questions.clear();
      _questions.addAll(decoded.map((item) => Question.fromMap(item, item['questionId'] ?? '')));
    } else {
      _seedDefaultQuestions();
    }

    if (resultsJson != null) {
      final List decoded = jsonDecode(resultsJson);
      _results.clear();
      _results.addAll(decoded.map((item) => AssessmentResult.fromMap(item, item['resultId'] ?? '')));
    }

    if (attemptsJson != null) {
      final List decoded = jsonDecode(attemptsJson);
      _attempts.clear();
      _attempts.addAll(decoded.map((item) => AssessmentAttempt.fromMap(item, item['attemptId'] ?? '')));
    }

    if (violationsJson != null) {
      final List decoded = jsonDecode(violationsJson);
      _violations.clear();
      _violations.addAll(decoded.map((item) => AssessmentViolation.fromMap(item, item['violationId'] ?? '')));
    }

    await _saveToLocalStorage();
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mca_students', jsonEncode(_students.map((s) => s.toMap()).toList()));
    await prefs.setString('mca_assessments', jsonEncode(_assessments.map((a) => a.toMap()).toList()));
    await prefs.setString('mca_questions', jsonEncode(_questions.map((q) => q.toMap()).toList()));
    await prefs.setString('mca_results', jsonEncode(_results.map((r) => r.toMap()).toList()));
    await prefs.setString('mca_attempts', jsonEncode(_attempts.map((a) => a.toMap()).toList()));
    await prefs.setString('mca_violations', jsonEncode(_violations.map((v) => v.toMap()).toList()));
  }

  void _seedDefaultStudents() {
    _students.clear();
  }

  Future<void> deleteStudent(String grnNumber) async {
    _students.removeWhere((s) => s.grnNumber.toUpperCase() == grnNumber.toUpperCase());
    await _saveToLocalStorage();
    if (_isFirestoreActive) {
      try {
        final snap = await FirebaseFirestore.instance.collection('students').where('grnNumber', isEqualTo: grnNumber.toUpperCase()).get();
        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        if (kDebugMode) print('Firestore delete student error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> clearAllStudents() async {
    _students.clear();
    await _saveToLocalStorage();
    try {
      final snap = await FirebaseFirestore.instance.collection('students').get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
      _isFirestoreActive = true;
    } catch (e) {
      if (kDebugMode) print('Firestore clear all students error: $e');
    }
    notifyListeners();
  }

  void _seedDefaultAssessments() {
    _assessments.clear();
    _assessments.addAll([
      Assessment(
        assessmentId: 'ASSESSMENT_GD_01',
        title: 'Group Discussion & Communication Round',
        round: AppConstants.roundGD,
        passingMarks: AppConstants.defaultGDPassingMarks,
        totalMarks: 5,
        isActive: true,
      ),
      Assessment(
        assessmentId: 'ASSESSMENT_TECH_01',
        title: 'Technical & Coding Skill Assessment',
        round: AppConstants.roundTechnical,
        passingMarks: AppConstants.defaultTechnicalPassingMarks,
        totalMarks: 6,
        isActive: true,
      ),
    ]);
  }

  void _seedDefaultQuestions() {
    _questions.clear();
    _questions.addAll([
      // GD Round Questions (Total Marks: 5, Passing: 3)
      Question(
        questionId: 'Q_GD_01',
        assessmentId: 'ASSESSMENT_GD_01',
        round: AppConstants.roundGD,
        questionText: 'Which of the following is the most effective approach to handle a disagreement during a Group Discussion?',
        options: [
          'A. Interrupt immediately and state that the opponent is wrong',
          'B. Listen actively, acknowledge their perspective, and present counter-arguments calmly with evidence',
          'C. Remain completely silent throughout the entire discussion',
          'D. Raise your voice to overpower other candidates'
        ],
        correctAnswer: 'B',
        marks: 2,
        order: 1,
      ),
      Question(
        questionId: 'Q_GD_02',
        assessmentId: 'ASSESSMENT_GD_01',
        round: AppConstants.roundGD,
        questionText: 'What is the primary objective of a Group Discussion in a technical campus placement selection process?',
        options: [
          'A. To test memorization of technical syntax',
          'B. To evaluate communication, teamwork, logical reasoning, and leadership skills',
          'C. To select the candidate who speaks the longest time',
          'D. To debate aggressively until one person wins'
        ],
        correctAnswer: 'B',
        marks: 2,
        order: 2,
      ),
      Question(
        questionId: 'Q_GD_03',
        assessmentId: 'ASSESSMENT_GD_01',
        round: AppConstants.roundGD,
        questionText: 'When initiating a Group Discussion topic, what should a candidate ideally include?',
        options: [
          'A. A short conclusion statement',
          'B. Definition of the topic, background context, and key discussion dimensions',
          'C. Personal anecdotes unrelated to the topic',
          'D. Immediate voting asking everyone to raise hands'
        ],
        correctAnswer: 'B',
        marks: 1,
        order: 3,
      ),

      // Technical Round Questions (Total Marks: 6, Passing: 4)
      Question(
        questionId: 'Q_TECH_01',
        assessmentId: 'ASSESSMENT_TECH_01',
        round: AppConstants.roundTechnical,
        questionText: 'What does OOP stand for and which core paradigm emphasizes data encapsulation?',
        options: [
          'A. Object Oriented Programming - Encapsulation binds code and data together',
          'B. Online Operating Process - Data is stored in cloud servers',
          'C. Open Object Protocol - Functions are publicly exposed without access modifiers',
          'D. Object Operation Parallelism - Multi-threaded execution model'
        ],
        correctAnswer: 'A',
        marks: 2,
        order: 1,
      ),
      Question(
        questionId: 'Q_TECH_02',
        assessmentId: 'ASSESSMENT_TECH_01',
        round: AppConstants.roundTechnical,
        questionText: 'In Data Structures, what is the average time complexity of searching an element in a balanced Binary Search Tree (BST)?',
        options: [
          'A. O(1)',
          'B. O(log N)',
          'C. O(N)',
          'D. O(N log N)'
        ],
        correctAnswer: 'B',
        marks: 2,
        order: 2,
      ),
      Question(
        questionId: 'Q_TECH_03',
        assessmentId: 'ASSESSMENT_TECH_01',
        round: AppConstants.roundTechnical,
        questionText: 'Which SQL keyword is used to eliminate duplicate records from a query result set?',
        options: [
          'A. UNIQUE',
          'B. DISTINCT',
          'C. GROUP BY',
          'D. REMOVE DUPLICATES'
        ],
        correctAnswer: 'B',
        marks: 2,
        order: 3,
      ),
    ]);
  }

  // --- FIRESTORE SYNCING ---

  Future<void> _loadFromFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1. Live stream for Assessment Attempts
      _attemptsSub?.cancel();
      _attemptsSub = firestore.collection('assessment_attempts').snapshots().listen(
        (snap) {
          _attempts.clear();
          for (var doc in snap.docs) {
            _attempts.add(AssessmentAttempt.fromMap(doc.data(), doc.id));
          }
          _saveToLocalStorage();
          notifyListeners();
        },
        onError: (e) {
          if (kDebugMode) print('Firestore attempts listener error: $e');
        },
      );

      // 2. Live stream for Assessment Violations
      _violationsSub?.cancel();
      _violationsSub = firestore.collection('assessment_violations').snapshots().listen(
        (snap) {
          _violations.clear();
          for (var doc in snap.docs) {
            _violations.add(AssessmentViolation.fromMap(doc.data(), doc.id));
          }
          _saveToLocalStorage();
          notifyListeners();
        },
        onError: (e) {
          if (kDebugMode) print('Firestore violations listener error: $e');
        },
      );

      // 3. Live stream for Students
      _studentsSub?.cancel();
      _studentsSub = firestore.collection('students').snapshots().listen(
        (snap) {
          if (snap.docs.isNotEmpty) {
            for (var doc in snap.docs) {
              final s = Student.fromMap(doc.data(), doc.id);
              final existingIdx = _students.indexWhere((x) => x.grnNumber.toUpperCase() == s.grnNumber.toUpperCase());
              if (existingIdx != -1) {
                _students[existingIdx] = s;
              } else {
                _students.add(s);
              }
            }
            _saveToLocalStorage();
            notifyListeners();
          }
        },
        onError: (e) {
          if (kDebugMode) print('Firestore students listener error: $e');
        },
      );

      // 4. Live stream for Results
      _resultsSub?.cancel();
      _resultsSub = firestore.collection('results').snapshots().listen(
        (snap) {
          _results.clear();
          for (var doc in snap.docs) {
            _results.add(AssessmentResult.fromMap(doc.data(), doc.id));
          }
          _saveToLocalStorage();
          notifyListeners();
        },
        onError: (e) {
          if (kDebugMode) print('Firestore results listener error: $e');
        },
      );

      // Load Assessments
      final assessSnap = await firestore.collection('assessments').get();
      _assessments.clear();
      for (var doc in assessSnap.docs) {
        _assessments.add(Assessment.fromMap(doc.data(), doc.id));
      }
      if (_assessments.isEmpty) {
        _seedDefaultAssessments();
        await syncAllToFirestore();
      }

      // Load Questions
      final qSnap = await firestore.collection('questions').get();
      _questions.clear();
      for (var doc in qSnap.docs) {
        _questions.add(Question.fromMap(doc.data(), doc.id));
      }
      if (_questions.isEmpty) {
        _seedDefaultQuestions();
        await syncAllToFirestore();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading from Firestore: $e');
    }
  }

  Future<void> syncAllToFirestore() async {
    if (!_isFirestoreActive) return;
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      for (var s in _students) {
        await firestore.collection('students').doc(s.studentId).set(s.toMap());
      }
      for (var a in _assessments) {
        await firestore.collection('assessments').doc(a.assessmentId).set(a.toMap());
      }
      for (var q in _questions) {
        await firestore.collection('questions').doc(q.questionId).set(q.toMap());
      }
      for (var r in _results) {
        await firestore.collection('results').doc(r.resultId).set(r.toMap());
      }
    } catch (e) {
      if (kDebugMode) print('Error syncing to Firestore: $e');
    }
  }

  // --- CRUD OPERATIONS ---

  // Students
  Future<String?> addStudents(List<Student> newStudents) async {
    _students.addAll(newStudents);
    await _saveToLocalStorage();
    
    String? firestoreError;
    // Save records to Cloud Firestore collection 'students'
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      for (var s in newStudents) {
        // Use GRN Number (e.g. 25MCA24451) as Document ID for easy lookup in Firebase Console
        await firestore.collection('students').doc(s.grnNumber.toUpperCase()).set(s.toMap());
      }
      _isFirestoreActive = true;
    } catch (e) {
      firestoreError = e.toString();
      if (kDebugMode) print('Firestore addStudents error: $e');
    }
    
    notifyListeners();
    return firestoreError;
  }

  // Assessments & Question Marks recalculation
  Assessment? getAssessmentByRound(String round) {
    try {
      return _assessments.firstWhere((a) => a.round.toLowerCase() == round.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<void> addAssessment(Assessment assessment) async {
    // Avoid duplicate round keys
    _assessments.removeWhere((a) => a.round.toLowerCase() == assessment.round.toLowerCase());
    _assessments.add(assessment);
    await _saveToLocalStorage();
    try {
      await FirebaseFirestore.instance.collection('assessments').doc(assessment.assessmentId).set(assessment.toMap());
      _isFirestoreActive = true;
    } catch (e) {
      if (kDebugMode) print('Firestore add assessment error: $e');
    }
    notifyListeners();
  }

  Future<void> deleteAssessment(String assessmentId) async {
    final target = _assessments.firstWhere((a) => a.assessmentId == assessmentId, orElse: () => Assessment(assessmentId: '', title: '', round: '', totalMarks: 0, passingMarks: 0));
    if (target.assessmentId.isNotEmpty) {
      _assessments.removeWhere((a) => a.assessmentId == assessmentId);
      _questions.removeWhere((q) => q.round.toLowerCase() == target.round.toLowerCase());
      await _saveToLocalStorage();
      try {
        await FirebaseFirestore.instance.collection('assessments').doc(assessmentId).delete();
      } catch (e) {
        if (kDebugMode) print('Firestore delete assessment error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> updateAssessmentPassingMarks(String round, int newPassingMarks) async {
    final idx = _assessments.indexWhere((a) => a.round.toLowerCase() == round.toLowerCase());
    if (idx != -1) {
      _assessments[idx] = _assessments[idx].copyWith(passingMarks: newPassingMarks);
      await _saveToLocalStorage();
      if (_isFirestoreActive) {
        await FirebaseFirestore.instance
            .collection('assessments')
            .doc(_assessments[idx].assessmentId)
            .update({'passingMarks': newPassingMarks});
      }
      notifyListeners();
    }
  }

  /// Register / Assign specific student GRNs to an Assessment Round
  Future<void> updateAssessmentRegisteredStudents(String round, List<String> studentGrns) async {
    final cleanList = studentGrns.map((g) => g.toUpperCase()).toList();
    final idx = _assessments.indexWhere((a) => a.round.toLowerCase() == round.toLowerCase());
    if (idx != -1) {
      _assessments[idx] = _assessments[idx].copyWith(registeredStudentGrns: cleanList);
      await _saveToLocalStorage();
      if (_isFirestoreActive) {
        await FirebaseFirestore.instance
            .collection('assessments')
            .doc(_assessments[idx].assessmentId)
            .update({'registeredStudentGrns': cleanList});
      }
      notifyListeners();
    }
  }

  /// Check if a student is authorized/registered to join an assessment round
  bool isStudentRegisteredForAssessment(String studentGrn, String round) {
    final assessment = getAssessmentByRound(round);
    if (assessment == null) return true; // Default allow if round metadata not configured
    final registered = assessment.registeredStudentGrns;
    if (registered.isEmpty || registered.contains('ALL')) return true; // All registered if empty or 'ALL'
    return registered.contains(studentGrn.toUpperCase());
  }

  // Questions
  List<Question> getQuestionsForRound(String round) {
    return _questions.where((q) => q.round.toLowerCase() == round.toLowerCase() && q.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> addQuestion(Question question) async {
    _questions.add(question);
    _recalculateAssessmentTotalMarks(question.round);
    await _saveToLocalStorage();
    if (_isFirestoreActive) {
      await FirebaseFirestore.instance.collection('questions').doc(question.questionId).set(question.toMap());
    }
    notifyListeners();
  }

  Future<void> updateQuestion(Question question) async {
    final idx = _questions.indexWhere((q) => q.questionId == question.questionId);
    if (idx != -1) {
      _questions[idx] = question;
      _recalculateAssessmentTotalMarks(question.round);
      await _saveToLocalStorage();
      if (_isFirestoreActive) {
        await FirebaseFirestore.instance.collection('questions').doc(question.questionId).set(question.toMap());
      }
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    final q = _questions.firstWhere((q) => q.questionId == questionId, orElse: () => Question(questionId: '', assessmentId: '', round: 'gd', questionText: '', options: [], correctAnswer: ''));
    if (q.questionId.isNotEmpty) {
      _questions.removeWhere((item) => item.questionId == questionId);
      _recalculateAssessmentTotalMarks(q.round);
      await _saveToLocalStorage();
      if (_isFirestoreActive) {
        await FirebaseFirestore.instance.collection('questions').doc(questionId).delete();
      }
      notifyListeners();
    }
  }

  void _recalculateAssessmentTotalMarks(String round) {
    final roundQuestions = _questions.where((q) => q.round.toLowerCase() == round.toLowerCase() && q.isActive);
    int total = 0;
    for (var q in roundQuestions) {
      total += q.marks;
    }
    final idx = _assessments.indexWhere((a) => a.round.toLowerCase() == round.toLowerCase());
    if (idx != -1) {
      _assessments[idx] = _assessments[idx].copyWith(totalMarks: total);
    }
  }

  // Submission & Evaluation (Requirement #11)  /// Update student certificate eligibility and final selection status
  Future<void> updateStudentCertificateEligibility({
    required String grnNumber,
    required bool isEligible,
    String? finalStatus,
  }) async {
    final idx = _students.indexWhere((s) => s.grnNumber.toUpperCase() == grnNumber.toUpperCase());
    if (idx != -1) {
      final updatedStudent = _students[idx].copyWith(
        certificateEligible: isEligible,
        finalStatus: finalStatus ?? (isEligible ? 'SELECTED' : 'PENDING'),
        certificateGeneratedAt: isEligible ? DateTime.now() : null,
      );
      _students[idx] = updatedStudent;
      await _saveToLocalStorage();
      try {
        await FirebaseFirestore.instance.collection('students').doc(updatedStudent.studentId).set(updatedStudent.toMap(), SetOptions(merge: true));
        _isFirestoreActive = true;
      } catch (e) {
        if (kDebugMode) print('Firestore update eligibility error: $e');
      }
      notifyListeners();
    }
  }

  /// Submit Assessment & Calculate Score
  Future<AssessmentResult> submitAssessment({
    required Student student,
    required String round,
    required Map<String, String> studentAnswers,
  }) async {
    final questions = getQuestionsForRound(round);
    final assessment = getAssessmentByRound(round);
    final passingMarks = assessment?.passingMarks ?? 3;

    int obtainedMarks = 0;
    int totalMarks = 0;

    for (var q in questions) {
      totalMarks += q.marks;
      final selectedOptLetter = studentAnswers[q.questionId];
      if (selectedOptLetter != null && selectedOptLetter.toUpperCase() == q.correctAnswer.toUpperCase()) {
        obtainedMarks += q.marks;
      }
    }

    final isPassed = obtainedMarks >= passingMarks;

    final result = AssessmentResult(
      resultId: 'RES_${student.grnNumber.toUpperCase()}_${round.toUpperCase()}',
      studentId: student.studentId,
      grnNumber: student.grnNumber,
      studentName: student.name,
      assessmentId: assessment?.assessmentId ?? 'ASSESSMENT_${round.toUpperCase()}',
      round: round,
      obtainedMarks: obtainedMarks,
      totalMarks: totalMarks,
      passingMarks: passingMarks,
      status: isPassed ? 'PASS' : 'FAIL',
      answersMap: studentAnswers,
      submittedAt: DateTime.now(),
    );

    // Save or overwrite result
    _results.removeWhere((r) => r.grnNumber.toUpperCase() == student.grnNumber.toUpperCase() && r.round.toLowerCase() == round.toLowerCase());
    _results.add(result);

    // Update Student GD / Technical / Certificate Status
    final sIdx = _students.indexWhere((s) => s.grnNumber.toUpperCase() == student.grnNumber.toUpperCase());
    if (sIdx != -1) {
      final currentStudent = _students[sIdx];
      String newGdStatus = currentStudent.gdStatus;
      String newTechStatus = currentStudent.technicalStatus;

      if (round.toLowerCase() == AppConstants.roundGD.toLowerCase()) {
        newGdStatus = isPassed ? 'PASS' : 'FAIL';
      } else if (round.toLowerCase() == AppConstants.roundTechnical.toLowerCase()) {
        newTechStatus = isPassed ? 'PASS' : 'FAIL';
      }

      // If passed both or completed required rounds, mark eligible
      bool isEligibleNow = currentStudent.certificateEligible || (newGdStatus == 'PASS' && newTechStatus == 'PASS') || isPassed;
      String newFinalStatus = isEligibleNow ? 'SELECTED' : currentStudent.finalStatus;

      final updatedStudent = currentStudent.copyWith(
        gdStatus: newGdStatus,
        technicalStatus: newTechStatus,
        certificateEligible: isEligibleNow,
        finalStatus: newFinalStatus,
        certificateGeneratedAt: isEligibleNow ? DateTime.now() : null,
      );

      _students[sIdx] = updatedStudent;

      try {
        await FirebaseFirestore.instance.collection('students').doc(updatedStudent.studentId).set(updatedStudent.toMap(), SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) print('Firestore student status update error: $e');
      }
    }

    await _saveToLocalStorage();

    if (_isFirestoreActive) {
      try {
        await FirebaseFirestore.instance.collection('results').doc(result.resultId).set(result.toMap());
      } catch (e) {
        if (kDebugMode) print('Firestore submit result error: $e');
      }
    }

    notifyListeners();
    return result;
  }

  AssessmentResult? getStudentResultForRound(String grnNumber, String round) {
    try {
      return _results.firstWhere(
        (r) => r.grnNumber.toUpperCase() == grnNumber.toUpperCase() && r.round.toLowerCase() == round.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Rules for Technical Round Unlock (Requirement #9):
  /// Technical Round becomes available if GD round is completed and passed
  bool isTechnicalRoundUnlockedForStudent(String grnNumber) {
    final gdResult = getStudentResultForRound(grnNumber, AppConstants.roundGD);
    return gdResult != null && gdResult.isPassed;
  }

  // --- STRICT ASSESSMENT SECURITY METHODS ---

  void updateSecurityPolicy(SecurityPolicy policy) {
    _securityPolicy = policy;
    notifyListeners();
  }

  AssessmentAttempt? getStudentActiveAttempt(String grnNumber, String round) {
    try {
      return _attempts.firstWhere(
        (a) => a.grnNumber.toUpperCase() == grnNumber.toUpperCase() && a.round.toLowerCase() == round.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Start or restore AssessmentAttempt
  Future<AssessmentAttempt> startAssessmentAttempt({
    required Student student,
    required String round,
  }) async {
    final now = DateTime.now();
    final cleanGrn = student.grnNumber.toUpperCase();
    final cleanRound = round.toLowerCase();

    // Check existing attempt in memory or Firestore
    var attempt = getStudentActiveAttempt(cleanGrn, cleanRound);

    if (attempt == null && _isFirestoreActive) {
      try {
        final doc = await FirebaseFirestore.instance.collection('assessment_attempts').doc('ATT_${cleanGrn}_${cleanRound.toUpperCase()}').get();
        if (doc.exists && doc.data() != null) {
          attempt = AssessmentAttempt.fromMap(doc.data()!, doc.id);
          _attempts.add(attempt);
        }
      } catch (e) {
        if (kDebugMode) print('Firestore fetch attempt error: $e');
      }
    }

    if (attempt != null) {
      // Rule 11: Locked attempts cannot be reopened by frontend
      if (attempt.isCompleted || attempt.isTerminated || attempt.isAbandoned) {
        return attempt;
      }

      // Rule 9: Timer security check on server
      if (attempt.isExpired(now)) {
        attempt = attempt.copyWith(status: 'ABANDONED');
        await _saveAttemptToFirestore(attempt);
        return attempt;
      }

      // Rule 3: Refresh - restore active attempt
      return attempt;
    }

    // Create new attempt & session lock
    final durationMins = (cleanRound == AppConstants.roundGD.toLowerCase()) ? 15 : 30;
    final attemptId = 'ATT_${cleanGrn}_${cleanRound.toUpperCase()}';
    final sessionId = 'SESS_${DateTime.now().millisecondsSinceEpoch}';

    final newAttempt = AssessmentAttempt(
      attemptId: attemptId,
      studentId: student.studentId,
      grnNumber: cleanGrn,
      round: cleanRound,
      status: 'IN_PROGRESS',
      startedAt: now,
      expiresAt: now.add(Duration(minutes: durationMins)),
      lastHeartbeatAt: now,
      sessionId: sessionId,
      violationCount: 0,
      obtainedMarks: 0,
      totalMarks: 0,
      isPassed: false,
    );

    _attempts.removeWhere((a) => a.attemptId == attemptId);
    _attempts.add(newAttempt);
    await _saveAttemptToFirestore(newAttempt);

    notifyListeners();
    return newAttempt;
  }

  /// 5-second Heartbeat & Session Collision Detection (Rule 4, 7, 8)
  Future<bool> sendHeartbeat({
    required String attemptId,
    required String sessionId,
  }) async {
    final idx = _attempts.indexWhere((a) => a.attemptId == attemptId);
    if (idx == -1) return false;

    var attempt = _attempts[idx];

    // Session collision: opened in another tab or device
    if (attempt.sessionId != sessionId) {
      if (kDebugMode) print('Session conflict detected for attempt $attemptId');
      return false;
    }

    if (!attempt.isActive) return false;

    final now = DateTime.now();

    // Check expiration
    if (attempt.isExpired(now)) {
      attempt = attempt.copyWith(status: 'ABANDONED', lastHeartbeatAt: now);
      _attempts[idx] = attempt;
      await _saveAttemptToFirestore(attempt);
      notifyListeners();
      return false;
    }

    // Update heartbeat
    attempt = attempt.copyWith(lastHeartbeatAt: now);
    _attempts[idx] = attempt;
    await _saveAttemptToFirestore(attempt);
    return true;
  }

  /// Record Security Violation & Enforce Strict Policy (Rule 1, 2, 5, 6, 16)
  Future<void> recordSecurityViolation({
    required String attemptId,
    required String studentId,
    required String grnNumber,
    required String eventType,
    required String details,
  }) async {
    final vId = 'VIOL_${DateTime.now().millisecondsSinceEpoch}';
    final violation = AssessmentViolation(
      violationId: vId,
      attemptId: attemptId,
      studentId: studentId,
      grnNumber: grnNumber,
      eventType: eventType,
      timestamp: DateTime.now(),
      details: details,
    );

    _violations.add(violation);

    // Save violation to Firestore
    if (_isFirestoreActive) {
      try {
        await FirebaseFirestore.instance.collection('assessment_violations').doc(vId).set(violation.toMap());
      } catch (e) {
        if (kDebugMode) print('Firestore violation save error: $e');
      }
    }

    final idx = _attempts.indexWhere((a) => a.attemptId == attemptId);
    if (idx != -1) {
      var attempt = _attempts[idx];
      final newCount = attempt.violationCount + 1;

      String newStatus = attempt.status;
      if (_securityPolicy.isStrictMode && newCount >= _securityPolicy.maxAllowedViolations) {
        newStatus = 'TERMINATED';
      }

      attempt = attempt.copyWith(
        violationCount: newCount,
        status: newStatus,
      );
      _attempts[idx] = attempt;
      await _saveAttemptToFirestore(attempt);
    }

    notifyListeners();
  }

  Future<void> _saveAttemptToFirestore(AssessmentAttempt attempt) async {
    if (_isFirestoreActive) {
      try {
        await FirebaseFirestore.instance
            .collection('assessment_attempts')
            .doc(attempt.attemptId)
            .set(attempt.toMap(), SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) print('Firestore save attempt error: $e');
      }
    }
  }

  /// Admin Reset Attempt (Override)
  Future<void> resetStudentAttempt(String attemptId) async {
    final idx = _attempts.indexWhere((a) => a.attemptId == attemptId);
    if (idx != -1) {
      _attempts.removeAt(idx);
      if (_isFirestoreActive) {
        try {
          await FirebaseFirestore.instance.collection('assessment_attempts').doc(attemptId).delete();
        } catch (e) {
          if (kDebugMode) print('Firestore reset attempt error: $e');
        }
      }
      notifyListeners();
    }
  }
}

