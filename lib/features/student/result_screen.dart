import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/result.dart';
import 'student_dashboard.dart';

class ResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isPassed = result.isPassed;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: Text(
          'Assessment Result',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isPassed ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Status Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isPassed ? AppTheme.successBg : AppTheme.dangerBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPassed ? Icons.verified_rounded : Icons.cancel_rounded,
                        size: 60,
                        color: isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isPassed ? 'PASSED' : 'FAILED',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPassed
                            ? 'Congratulations! You have successfully cleared the required passing threshold.'
                            : 'Minimum passing score was not reached for this round.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        result.round == AppConstants.roundGD ? 'Round 1 — GD Round' : 'Round 2 — Technical Round',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student GRN: ${result.grnNumber}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                      ),

                      const SizedBox(height: 20),

                      // Responsive Score Breakdown Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          final tiles = [
                            _buildScoreTile(
                              title: 'Obtained Score',
                              value: '${result.obtainedMarks}',
                              color: isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                            ),
                            _buildScoreTile(
                              title: 'Total Marks',
                              value: '${result.totalMarks}',
                              color: AppTheme.primaryBlue,
                            ),
                            _buildScoreTile(
                              title: 'Passing Score',
                              value: '${result.passingMarks}',
                              color: AppTheme.textDark,
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: t))).toList(),
                            );
                          }

                          return Row(
                            children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: t))).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (ctx) => const StudentDashboardScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Back to Dashboard'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreTile({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
