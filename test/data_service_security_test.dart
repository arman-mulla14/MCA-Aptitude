import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mca_aptitude_app/services/data_service.dart';
import 'package:mca_aptitude_app/models/student.dart';
import 'package:mca_aptitude_app/models/security_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DataService Security & Attempt Logic Tests', () {
    final testStudent = Student(
      studentId: 'STU_SEC_01',
      grnNumber: '25MCA99999',
      mobileNumber: '9876543210',
      name: 'Test Security Student',
      email: 'test@mca.edu',
    );

    test('startAssessmentAttempt creates new attempt with session lock', () async {
      final dataService = DataService();
      await Future.delayed(Duration.zero); // Wait for async init

      final attempt = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      expect(attempt.attemptId, equals('ATT_25MCA99999_GD'));
      expect(attempt.grnNumber, equals('25MCA99999'));
      expect(attempt.round, equals('gd'));
      expect(attempt.status, equals('IN_PROGRESS'));
      expect(attempt.sessionId, startsWith('SESS_'));
      expect(attempt.violationCount, equals(0));
    });

    test('startAssessmentAttempt returns existing active attempt (Restore on Refresh)', () async {
      final dataService = DataService();
      await Future.delayed(Duration.zero);

      final attempt1 = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      final attempt2 = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      expect(attempt2.sessionId, equals(attempt1.sessionId));
      expect(attempt2.attemptId, equals(attempt1.attemptId));
    });

    test('sendHeartbeat succeeds for matching session and fails on session collision', () async {
      final dataService = DataService();
      await Future.delayed(Duration.zero);

      final attempt = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      // Matching sessionId
      final ok = await dataService.sendHeartbeat(
        attemptId: attempt.attemptId,
        sessionId: attempt.sessionId,
      );
      expect(ok, isTrue);

      // Session collision (different session ID from another tab/device)
      final collisionOk = await dataService.sendHeartbeat(
        attemptId: attempt.attemptId,
        sessionId: 'SESS_OTHER_TAB',
      );
      expect(collisionOk, isFalse);
    });

    test('recordSecurityViolation increments count and auto-terminates at max violations', () async {
      final dataService = DataService();
      await Future.delayed(Duration.zero);

      // Set strict policy with max 2 violations
      dataService.updateSecurityPolicy(const SecurityPolicy(
        isStrictMode: true,
        maxAllowedViolations: 2,
      ));

      final attempt = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      // Violation 1
      await dataService.recordSecurityViolation(
        attemptId: attempt.attemptId,
        studentId: testStudent.studentId,
        grnNumber: testStudent.grnNumber,
        eventType: 'NEW_TAB',
        details: 'Opened new tab',
      );

      var updated = dataService.getStudentActiveAttempt(testStudent.grnNumber, 'gd');
      expect(updated?.violationCount, equals(1));
      expect(updated?.status, equals('IN_PROGRESS'));

      // Violation 2 (reaches max threshold)
      await dataService.recordSecurityViolation(
        attemptId: attempt.attemptId,
        studentId: testStudent.studentId,
        grnNumber: testStudent.grnNumber,
        eventType: 'WINDOW_BLUR',
        details: 'Window lost focus',
      );

      updated = dataService.getStudentActiveAttempt(testStudent.grnNumber, 'gd');
      expect(updated?.violationCount, equals(2));
      expect(updated?.status, equals('TERMINATED'));
      expect(updated?.isTerminated, isTrue);
    });

    test('resetStudentAttempt allows admin to unlock a terminated student attempt', () async {
      final dataService = DataService();
      await Future.delayed(Duration.zero);

      final attempt = await dataService.startAssessmentAttempt(
        student: testStudent,
        round: 'gd',
      );

      await dataService.recordSecurityViolation(
        attemptId: attempt.attemptId,
        studentId: testStudent.studentId,
        grnNumber: testStudent.grnNumber,
        eventType: 'FULLSCREEN_EXIT',
        details: 'Exited fullscreen',
      );

      // Admin resets attempt
      await dataService.resetStudentAttempt(attempt.attemptId);

      final resetAttempt = dataService.getStudentActiveAttempt(testStudent.grnNumber, 'gd');
      expect(resetAttempt, isNull);
    });
  });
}
