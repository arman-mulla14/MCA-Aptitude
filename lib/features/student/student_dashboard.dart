import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/student.dart';
import '../../models/assessment.dart';
import '../../models/result.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/certificate_pdf_service.dart';
import '../../widgets/certificate_preview_widget.dart';
import 'assessment_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  void _showAppreciationCertificateModal(
    BuildContext context,
    Student student,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Official Appreciation Certificate',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CertificatePreviewWidget(student: student),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await CertificatePdfService.printOrShareCertificate(student);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Certificate (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dataService = Provider.of<DataService>(context);

    final Student student = authService.currentStudent!;
    final List<Assessment> assessments = dataService.assessments;
    final List<AssessmentResult> studentResults = dataService.results.where(
      (r) => r.grnNumber.toUpperCase() == student.grnNumber.toUpperCase(),
    ).toList();

    final bool isCertificateAvailable = student.certificateEligible ||
        student.finalStatus == 'SELECTED' ||
        (student.gdStatus == 'PASS' && student.technicalStatus == 'PASS') ||
        studentResults.any((r) => r.isPassed);

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: AppTheme.accentBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Assessment Portal',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                  ),
                  Text(
                    AppConstants.departmentName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                authService.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out of Student Portal')),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.dangerRed,
                side: const BorderSide(color: AppTheme.dangerRed),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section Banner (Responsive Layout)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Welcome, ${student.name.isNotEmpty ? student.name : "Student"} 👋',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'GRN: ${student.grnNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MCA Skill & Technical Aptitude Assessment Series',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appreciation Certificate Section Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCertificateAvailable ? AppTheme.surfaceBlue : AppTheme.bgCanvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCertificateAvailable ? AppTheme.accentBlue.withOpacity(0.3) : AppTheme.borderColor,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  final headerWidget = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: isCertificateAvailable ? const Color(0xFFFFB703) : AppTheme.textMuted,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appreciation Certificate',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCertificateAvailable
                                  ? 'Your official department Appreciation Certificate is ready!'
                                  : 'Certificate will be available after the final list is published.',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionsWidget = isCertificateAvailable
                      ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showAppreciationCertificateModal(context, student),
                              icon: const Icon(Icons.visibility_rounded, size: 18),
                              label: const Text('View Certificate'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await CertificatePdfService.printOrShareCertificate(student);
                              },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Download Certificate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerWidget,
                        if (isCertificateAvailable) ...[
                          const SizedBox(height: 16),
                          actionsWidget,
                        ],
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerWidget),
                      if (isCertificateAvailable) ...[
                        const SizedBox(width: 16),
                        actionsWidget,
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Assessment Rounds (${assessments.length} Available)',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            const SizedBox(height: 16),

            // Assessment Cards Layout
            Builder(
              builder: (context) {
                bool previousPassed = true;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    final cardWidgets = assessments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final a = entry.value;
                      final result = dataService.getStudentResultForRound(student.grnNumber, a.round);
                      final isUnlocked = i == 0 || previousPassed;
                      previousPassed = result != null && result.isPassed;

                      return SizedBox(
                        width: isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildAssessmentCard(
                            context: context,
                            dataService: dataService,
                            round: a.round,
                            title: 'Round ${i + 1} — ${a.title}',
                            subtitle: 'Total Questions: ${dataService.getQuestionsForRound(a.round).length} • Total Marks: ${a.totalMarks}',
                            assessment: a,
                            result: result,
                            isUnlocked: isUnlocked,
                            student: student,
                            icon: i == 0 ? Icons.groups_rounded : (i == 1 ? Icons.code_rounded : Icons.psychology_rounded),
                          ),
                        ),
                      );
                    }).toList();

                    return Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      children: cardWidgets,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Attempts Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Assessment Submission Record',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Automated evaluation scores and status log',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        if (isCertificateAvailable) ...[
                          TextButton.icon(
                            onPressed: () => _showAppreciationCertificateModal(context, student),
                            icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                            label: const Text('View Certificate'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    studentResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'You have not attempted any assessment round yet. Start with Round 1 above!',
                                style: GoogleFonts.inter(color: AppTheme.textMuted),
                              ),
                            ),
                          )
                        : Column(
                            children: studentResults.map((r) => _buildResultSummaryTile(r, assessments)).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard({
    required BuildContext context,
    required DataService dataService,
    required String round,
    required String title,
    required String subtitle,
    required Assessment assessment,
    required AssessmentResult? result,
    required bool isUnlocked,
    required Student student,
    required IconData icon,
  }) {
    String statusLabel = 'Available';
    Color statusColor = AppTheme.accentBlue;
    Color statusBg = AppTheme.surfaceBlue;

    final attempt = dataService.getStudentActiveAttempt(student.grnNumber, round);

    if (!isUnlocked) {
      statusLabel = 'Locked';
      statusColor = AppTheme.textMuted;
      statusBg = AppTheme.bgCanvas;
    } else if (attempt != null && (attempt.isTerminated || attempt.violationCount >= dataService.securityPolicy.maxAllowedViolations)) {
      statusLabel = 'Disqualified (Admin Permission Needed)';
      statusColor = AppTheme.dangerRed;
      statusBg = AppTheme.dangerRed.withOpacity(0.12);
    } else if (result != null) {
      statusLabel = 'Completed (${result.status})';
      statusColor = result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed;
      statusBg = result.isPassed ? AppTheme.successBg : AppTheme.dangerBg;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppTheme.surfaceBlue : AppTheme.bgCanvas,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUnlocked ? icon : Icons.lock_outline_rounded,
                    color: isUnlocked ? AppTheme.accentBlue : AppTheme.textMuted,
                    size: 28,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text(
                  'Passing Marks: ',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                ),
                Text(
                  '${assessment.passingMarks} Marks',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!isUnlocked)
                    ? null
                    : () {
                        final dataService = Provider.of<DataService>(context, listen: false);

                        // Check if student was terminated / disqualified and needs Admin permission to rejoin
                        final currentAttempt = dataService.getStudentActiveAttempt(student.grnNumber, round);
                        if (currentAttempt != null && (currentAttempt.isTerminated || currentAttempt.violationCount >= dataService.securityPolicy.maxAllowedViolations)) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Row(
                                children: [
                                  const Icon(Icons.gavel_rounded, color: AppTheme.dangerRed),
                                  const SizedBox(width: 8),
                                  Text('Admin Permission Required', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: Text(
                                'Your attempt for "$title" was terminated due to security violations. You cannot rejoin until the Administrator grants permission by unlocking your attempt in the Live Track security portal.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                              ],
                            ),
                          );
                          return;
                        }

                        final isRegistered = dataService.isStudentRegisteredForAssessment(student.grnNumber, round);
                        if (!isRegistered) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Row(
                                children: [
                                  const Icon(Icons.lock_rounded, color: AppTheme.dangerRed),
                                  const SizedBox(width: 8),
                                  Text('Access Restricted', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: Text(
                                'You are not registered or authorized for "$title" by the Administrator. Please contact your MCA Department coordinator.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                              ],
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AssessmentScreen(
                              round: round,
                              student: student,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: attempt != null && attempt.isTerminated
                      ? AppTheme.dangerRed
                      : (result != null ? AppTheme.headerNavy : AppTheme.accentBlue),
                ),
                child: Text(
                  attempt != null && attempt.isTerminated
                      ? 'Rejoin (Requires Admin Permission)'
                      : (result != null ? 'Retake Assessment' : 'Start Assessment'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummaryTile(AssessmentResult result, List<Assessment> assessments) {
    final matchingAssessment = assessments.firstWhere(
      (a) => a.round.toLowerCase() == result.round.toLowerCase(),
      orElse: () => Assessment(assessmentId: '', title: result.round.toUpperCase(), round: result.round, totalMarks: result.totalMarks, passingMarks: result.passingMarks),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            result.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchingAssessment.title,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  'Obtained Score: ${result.obtainedMarks} / ${result.totalMarks} • Passing Threshold: ${result.passingMarks} Marks',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: result.isPassed ? AppTheme.successBg : AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.status,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
