import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/data_service.dart';
import '../../../widgets/stat_card.dart';

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);

    final totalStudents = dataService.students.length;
    final totalAssessments = dataService.assessments.length;

    final gdAssessment = dataService.getAssessmentByRound(AppConstants.roundGD);
    final techAssessment = dataService.getAssessmentByRound(AppConstants.roundTechnical);

    final results = dataService.results;

    // Participated Students count (unique GRNs who attempted at least 1 assessment)
    final participatedGrns = results.map((r) => r.grnNumber.toUpperCase()).toSet();
    final totalParticipated = participatedGrns.length;

    // Passed Students count (unique GRNs who passed both rounds or achieved pass status)
    int passedCount = 0;
    int failedCount = 0;

    for (var r in results) {
      if (r.isPassed) {
        passedCount++;
      } else {
        failedCount++;
      }
    }

    final passRate = results.isNotEmpty ? ((passedCount / results.length) * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
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
                    'Admin Dashboard Overview',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.headerNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time overview of student participation, assessment metrics, and department pass rates',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dataService.isFirestoreActive ? AppTheme.successBg : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dataService.isFirestoreActive ? AppTheme.successGreen : AppTheme.warningOrange,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: dataService.isFirestoreActive ? AppTheme.successGreen : AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dataService.isFirestoreActive ? 'Cloud Firestore Sync' : 'Local Storage Mode',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dataService.isFirestoreActive ? AppTheme.successGreen : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 700
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Total Students Registered',
                    value: totalStudents.toString(),
                    icon: Icons.people_alt_rounded,
                    iconBgColor: AppTheme.surfaceBlue,
                    iconColor: AppTheme.accentBlue,
                    subtitle: 'Imported via Excel / Manual',
                  ),
                  StatCard(
                    title: 'Total Assessment Rounds',
                    value: totalAssessments.toString(),
                    icon: Icons.assignment_rounded,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: AppTheme.primaryBlue,
                    subtitle: 'GD & Technical Rounds',
                  ),
                  StatCard(
                    title: 'GD Round Status',
                    value: (gdAssessment?.isActive ?? true) ? 'Active' : 'Disabled',
                    icon: Icons.groups_rounded,
                    iconBgColor: AppTheme.successBg,
                    iconColor: AppTheme.successGreen,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pass: ${gdAssessment?.passingMarks ?? 3} Marks',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  StatCard(
                    title: 'Technical Round Status',
                    value: (techAssessment?.isActive ?? true) ? 'Active' : 'Disabled',
                    icon: Icons.code_rounded,
                    iconBgColor: const Color(0xFFF0FDF4),
                    iconColor: AppTheme.successGreen,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pass: ${techAssessment?.passingMarks ?? 4} Marks',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  StatCard(
                    title: 'Students Participated',
                    value: totalParticipated.toString(),
                    icon: Icons.fact_check_rounded,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: AppTheme.warningOrange,
                    subtitle: '$totalParticipated / $totalStudents students',
                  ),
                  StatCard(
                    title: 'Disqualified (Cheating)',
                    value: dataService.attempts.where((a) => a.isTerminated).length.toString(),
                    icon: Icons.gavel_rounded,
                    iconBgColor: AppTheme.dangerRed.withOpacity(0.1),
                    iconColor: AppTheme.dangerRed,
                    subtitle: 'Terminated for security violations',
                  ),
                  StatCard(
                    title: 'Total Submissions Passed',
                    value: passedCount.toString(),
                    icon: Icons.verified_user_rounded,
                    iconBgColor: AppTheme.successBg,
                    iconColor: AppTheme.successGreen,
                    subtitle: '$passRate% Pass Rate',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Charts & Round Breakdown Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pass/Fail Pie Chart
              Expanded(
                flex: 5,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Assessment Performance',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Distribution of Passed vs Failed round attempts',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: results.isEmpty
                              ? Center(
                                  child: Text(
                                    'No assessment submissions recorded yet.',
                                    style: GoogleFonts.inter(color: AppTheme.textMuted),
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sectionsSpace: 4,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      PieChartSectionData(
                                        color: AppTheme.successGreen,
                                        value: passedCount.toDouble(),
                                        title: 'Passed\n$passedCount',
                                        radius: 60,
                                        titleStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      PieChartSectionData(
                                        color: AppTheme.dangerRed,
                                        value: failedCount.toDouble(),
                                        title: 'Failed\n$failedCount',
                                        radius: 60,
                                        titleStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Passed Attempts', AppTheme.successGreen),
                            const SizedBox(width: 24),
                            _buildLegendItem('Failed Attempts', AppTheme.dangerRed),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Round Status Info Card
              Expanded(
                flex: 7,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assessment Rounds Configuration',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current rules, configured passing criteria and question bank metrics',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),

                        dataService.assessments.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text('No assessment rounds created yet.', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dataService.assessments.length,
                                separatorBuilder: (c, i) => const Divider(height: 20),
                                itemBuilder: (ctx, idx) {
                                  final a = dataService.assessments[idx];
                                  final roundQuestions = dataService.getQuestionsForRound(a.round);
                                  return _buildRoundInfoRow(
                                    roundName: 'Round ${idx + 1} — ${a.title}',
                                    passingMarks: a.passingMarks,
                                    totalQuestions: roundQuestions.length,
                                    totalMarks: a.totalMarks,
                                    icon: idx == 0
                                        ? Icons.groups_rounded
                                        : (idx == 1 ? Icons.code_rounded : Icons.assignment_rounded),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildRoundInfoRow({
    required String roundName,
    required int passingMarks,
    required int totalQuestions,
    required int totalMarks,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roundName,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalQuestions MCQs in Question Bank • Total Marks: $totalMarks',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
          ),
          child: Text(
            'Passing Target: $passingMarks Marks',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
          ),
        ),
      ],
    );
  }
}
