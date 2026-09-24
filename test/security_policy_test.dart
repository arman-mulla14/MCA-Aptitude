import 'package:flutter_test/flutter_test.dart';
import 'package:mca_aptitude_app/models/assessment_attempt.dart';
import 'package:mca_aptitude_app/models/assessment_violation.dart';
import 'package:mca_aptitude_app/models/security_policy.dart';

void main() {
  group('Security Policy Model Tests', () {
    test('Default SecurityPolicy should have strict mode enabled and max 3 violations', () {
      const policy = SecurityPolicy();
      expect(policy.isStrictMode, isTrue);
      expect(policy.maxAllowedViolations, equals(3));
      expect(policy.requireFullscreen, isTrue);
      expect(policy.blockDevTools, isTrue);
      expect(policy.heartbeatIntervalSeconds, equals(5));
      expect(policy.heartbeatTimeoutSeconds, equals(30));
    });

    test('SecurityPolicy copyWith updates properties correctly', () {
      const policy = SecurityPolicy();
      final updated = policy.copyWith(
        isStrictMode: false,
        maxAllowedViolations: 5,
        requireFullscreen: false,
      );
      expect(updated.isStrictMode, isFalse);
      expect(updated.maxAllowedViolations, equals(5));
      expect(updated.requireFullscreen, isFalse);
      expect(updated.blockDevTools, isTrue); // unchanged
    });

    test('SecurityPolicy serialization to/from Map', () {
      const policy = SecurityPolicy(
        isStrictMode: true,
        maxAllowedViolations: 2,
        requireFullscreen: true,
      );
      final map = policy.toMap();
      final restored = SecurityPolicy.fromMap(map);
      expect(restored.isStrictMode, isTrue);
      expect(restored.maxAllowedViolations, equals(2));
      expect(restored.requireFullscreen, isTrue);
    });
  });

  group('AssessmentViolation Model Tests', () {
    test('AssessmentViolation maps correctly to/from Map', () {
      final now = DateTime.now();
      final violation = AssessmentViolation(
        violationId: 'V_101',
        attemptId: 'ATT_01',
        studentId: 'STU_01',
        grnNumber: '25MCA24451',
        eventType: 'NEW_TAB',
        timestamp: now,
        details: 'Candidate opened another browser tab',
      );

      final map = violation.toMap();
      expect(map['eventType'], equals('NEW_TAB'));
      expect(map['grnNumber'], equals('25MCA24451'));

      final restored = AssessmentViolation.fromMap(map);
      expect(restored.violationId, equals('V_101'));
      expect(restored.eventType, equals('NEW_TAB'));
      expect(restored.details, contains('opened another browser tab'));
    });
  });

  group('AssessmentAttempt Model Tests', () {
    test('AssessmentAttempt state flags work properly', () {
      final now = DateTime.now();
      final attempt = AssessmentAttempt(
        attemptId: 'ATT_TEST_01',
        studentId: 'STU_01',
        grnNumber: '25MCA24451',
        round: 'gd',
        status: 'IN_PROGRESS',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        lastHeartbeatAt: now,
        sessionId: 'SESS_12345',
        violationCount: 0,
      );

      expect(attempt.isInProgress, isTrue);
      expect(attempt.isCompleted, isFalse);
      expect(attempt.isTerminated, isFalse);
      expect(attempt.isAbandoned, isFalse);
      expect(attempt.isActive, isTrue);
    });

    test('AssessmentAttempt expiration calculation', () {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 20));
      final pastExpire = pastStart.add(const Duration(minutes: 15));

      final attempt = AssessmentAttempt(
        attemptId: 'ATT_EXPIRED',
        studentId: 'STU_01',
        grnNumber: '25MCA24451',
        round: 'gd',
        status: 'IN_PROGRESS',
        startedAt: pastStart,
        expiresAt: pastExpire,
        lastHeartbeatAt: pastStart,
        sessionId: 'SESS_9999',
      );

      expect(attempt.isExpired(DateTime.now()), isTrue);
    });
  });
}
