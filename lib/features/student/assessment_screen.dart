import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/student.dart';
import '../../models/question.dart';
import '../../models/assessment_attempt.dart';
import '../../services/data_service.dart';
import '../../utils/security_utils.dart';
import 'result_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final String round;
  final Student student;

  const AssessmentScreen({
    super.key,
    required this.round,
    required this.student,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  final Map<String, String> _selectedAnswers = {}; // questionId -> 'A' | 'B' | 'C' | 'D'
  bool _isSubmitting = false;
  AssessmentAttempt? _attempt;
  Timer? _heartbeatTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isInitializingAttempt = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestHTMLFullscreen();
    _initializeAttemptAndSecurity();
  }

  Future<void> _initializeAttemptAndSecurity() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    final attempt = await dataService.startAssessmentAttempt(
      student: widget.student,
      round: widget.round,
    );

    if (!mounted) return;

    // Check if attempt is already ended
    if (attempt.isCompleted || attempt.isTerminated || attempt.isAbandoned) {
      final result = dataService.getStudentResultForRound(widget.student.grnNumber, widget.round);
      if (result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => ResultScreen(result: result)),
        );
        return;
      }
    }

    final now = DateTime.now();
    final remaining = attempt.expiresAt.difference(now).inSeconds;

    setState(() {
      _attempt = attempt;
      _remainingSeconds = remaining > 0 ? remaining : 0;
      _isInitializingAttempt = false;
    });

    // Register Web Security violation callbacks
    enableAssessmentSecurity(onViolation: (eventType, details) {
      _handleSecurityViolation(eventType, details);
    });

    // 5-second Heartbeat Timer Loop (Rule 4)
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_attempt == null || _isSubmitting) return;
      final ok = await dataService.sendHeartbeat(
        attemptId: _attempt!.attemptId,
        sessionId: _attempt!.sessionId,
      );

      if (!ok && mounted && !_isSubmitting) {
        _handleSessionConflictOrExpiry();
      }
    });

    // 1-second Countdown Timer Loop (Rule 9)
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isSubmitting) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
        _forceSubmitOnExpiry();
      }
    });
  }

  void _handleSessionConflictOrExpiry() {
    _forceSubmitAndKickOut('Session Conflict / Time Expired', 'Your assessment session was closed or expired.');
  }

  void _forceSubmitOnExpiry() {
    _forceSubmitAndKickOut('Time Expired', 'The allocated time for this assessment has finished.');
  }

  Future<void> _handleSecurityViolation(String eventType, String details) async {
    if (_attempt == null || _isSubmitting || !mounted) return;

    final dataService = Provider.of<DataService>(context, listen: false);
    await dataService.recordSecurityViolation(
      attemptId: _attempt!.attemptId,
      studentId: widget.student.studentId,
      grnNumber: widget.student.grnNumber,
      eventType: eventType,
      details: details,
    );

    final updatedAttempt = dataService.getStudentActiveAttempt(widget.student.grnNumber, widget.round);
    if (updatedAttempt != null) {
      setState(() {
        _attempt = updatedAttempt;
      });

      if (updatedAttempt.isTerminated) {
        _forceSubmitAndKickOut(
          'Assessment Terminated',
          'Maximum allowed security violations (${dataService.securityPolicy.maxAllowedViolations}) exceeded ($eventType).',
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Security Warning ($eventType): Violation recorded (${_attempt?.violationCount ?? 1}/${dataService.securityPolicy.maxAllowedViolations})'),
        backgroundColor: AppTheme.warningOrange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    disableAssessmentSecurity();
    exitHTMLFullscreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      if (!_isSubmitting && _attempt != null) {
        _handleSecurityViolation('WINDOW_FOCUS_LOST', 'App lifecycle state changed to $state');
      }
    }
  }

  Future<void> _forceSubmitAndKickOut(String title, String message) async {
    if (!mounted || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final result = await dataService.submitAssessment(
        student: widget.student,
        round: widget.round,
        studentAnswers: _selectedAnswers,
      );

      disableAssessmentSecurity();
      exitHTMLFullscreen();

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(title, style: const TextStyle(color: AppTheme.dangerRed)),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                child: const Text('Acknowledge'),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (ctx) => ResultScreen(result: result)),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSubmitConfirmationDialog(List<Question> questions) {
    int answeredCount = _selectedAnswers.length;
    int remainingCount = questions.length - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppTheme.accentBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Submit Assessment?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to submit your final answers for this assessment?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$answeredCount / ${questions.length}',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                      ),
                      Text('Answered', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '$remainingCount',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: remainingCount > 0 ? AppTheme.warningOrange : AppTheme.textMuted,
                        ),
                      ),
                      Text('Unanswered', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _executeSubmission();
                  },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSubmission() async {
    setState(() => _isSubmitting = true);

    try {
      final dataService = Provider.of<DataService>(context, listen: false);

      final result = await dataService.submitAssessment(
        student: widget.student,
        round: widget.round,
        studentAnswers: _selectedAnswers,
      );

      if (mounted) {
        disableAssessmentSecurity();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => ResultScreen(result: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final questions = dataService.getQuestionsForRound(widget.round);
    final assessment = dataService.getAssessmentByRound(widget.round);

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.warningOrange),
              const SizedBox(height: 16),
              Text(
                'No active questions available for this round.',
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final selectedOptionLetter = _selectedAnswers[currentQuestion.questionId];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Back navigation is disabled during the assessment.'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      },
      child: Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assessment?.title ?? (widget.round == AppConstants.roundGD ? 'Round 1 — GD Round' : 'Round 2 — Technical Round'),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            Text(
              'MCA Technical Assessment',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          // Server Countdown Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds < 300 ? AppTheme.dangerBg : AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _remainingSeconds < 300 ? AppTheme.dangerRed : AppTheme.accentBlue,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 16,
                  color: _remainingSeconds < 300 ? AppTheme.dangerRed : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_remainingSeconds),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 300 ? AppTheme.dangerRed : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Security Violation Badge
          if (_attempt != null && _attempt!.violationCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warningOrange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppTheme.warningOrange),
                  const SizedBox(width: 4),
                  Text(
                    'Violations: ${_attempt!.violationCount}/${dataService.securityPolicy.maxAllowedViolations}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showSubmitConfirmationDialog(questions),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(questions, currentQuestion, selectedOptionLetter);
          } else {
            return _buildDesktopLayout(questions, currentQuestion, selectedOptionLetter);
          }
        },
      ),
    ));
  }

  /// Mobile Responsive Layout (Single column with horizontal question palette chip bar)
  Widget _buildMobileLayout(List<Question> questions, Question currentQuestion, String? selectedOptionLetter) {
    return Column(
      children: [
        // Horizontal Question Palette Bar (Mobile)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question Palette',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                  ),
                  Text(
                    'Tap number to jump',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: questions.length,
                  itemBuilder: (context, idx) {
                    final q = questions[idx];
                    final isAnswered = _selectedAnswers.containsKey(q.questionId);
                    final isCurrent = idx == _currentQuestionIndex;

                    return GestureDetector(
                      onTap: () => setState(() => _currentQuestionIndex = idx),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.accentBlue
                              : isAnswered
                                  ? AppTheme.successBg
                                  : AppTheme.bgCanvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.accentBlue
                                : isAnswered
                                    ? AppTheme.successGreen
                                    : AppTheme.borderColor,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                      ? AppTheme.successGreen
                                      : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Main Question Scroll Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    Text(
                      'Marks: ${currentQuestion.marks}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceBlue,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                  ),
                ),
                const SizedBox(height: 16),

                // Question Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQuestion.questionText,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headerNavy,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options List
                        ...currentQuestion.options.map((optionText) {
                          String optionLetter = optionText.trim().substring(0, 1).toUpperCase();
                          bool isSelected = selectedOptionLetter == optionLetter;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[currentQuestion.questionId] = optionLetter;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.surfaceBlue : AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.accentBlue : AppTheme.bgCanvas,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          optionLetter,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected ? Colors.white : AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Mobile Sticky Bottom Stepper Bar (50/50 buttons, no overflow!)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.cardWhite,
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentQuestionIndex > 0
                      ? () => setState(() => _currentQuestionIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _currentQuestionIndex < questions.length - 1
                    ? ElevatedButton.icon(
                        onPressed: () => setState(() => _currentQuestionIndex++),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next'),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showSubmitConfirmationDialog(questions),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Desktop / Laptop Split View Layout
  Widget _buildDesktopLayout(List<Question> questions, Question currentQuestion, String? selectedOptionLetter) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Main Question Body
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    Text(
                      'Marks: ${currentQuestion.marks}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceBlue,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                  ),
                ),

                const SizedBox(height: 24),

                // Question Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQuestion.questionText,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headerNavy,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options List
                        ...currentQuestion.options.map((optionText) {
                          String optionLetter = optionText.trim().substring(0, 1).toUpperCase();
                          bool isSelected = selectedOptionLetter == optionLetter;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[currentQuestion.questionId] = optionLetter;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.surfaceBlue : AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.accentBlue : AppTheme.bgCanvas,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          optionLetter,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom Stepper Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentQuestionIndex > 0
                          ? () => setState(() => _currentQuestionIndex--)
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous Question'),
                    ),
                    if (_currentQuestionIndex < questions.length - 1)
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentQuestionIndex++),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Next Question'),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _showSubmitConfirmationDialog(questions),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Submit Assessment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1, color: AppTheme.borderColor),

        // Right Sidebar Question Palette
        Expanded(
          flex: 3,
          child: Container(
            color: AppTheme.cardWhite,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Palette',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jump directly to any question',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, idx) {
                    final q = questions[idx];
                    final isAnswered = _selectedAnswers.containsKey(q.questionId);
                    final isCurrent = idx == _currentQuestionIndex;

                    return InkWell(
                      onTap: () => setState(() => _currentQuestionIndex = idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.accentBlue
                              : isAnswered
                                  ? AppTheme.successBg
                                  : AppTheme.bgCanvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.accentBlue
                                : isAnswered
                                    ? AppTheme.successGreen
                                    : AppTheme.borderColor,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                      ? AppTheme.successGreen
                                      : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                Column(
                  children: [
                    _buildPaletteLegendItem('Current', AppTheme.accentBlue, Colors.white),
                    const SizedBox(height: 8),
                    _buildPaletteLegendItem('Answered', AppTheme.successBg, AppTheme.successGreen),
                    const SizedBox(height: 8),
                    _buildPaletteLegendItem('Unanswered', AppTheme.bgCanvas, AppTheme.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteLegendItem(String label, Color bg, Color textCol) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
