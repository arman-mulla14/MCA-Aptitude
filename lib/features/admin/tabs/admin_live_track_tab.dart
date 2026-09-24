import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/student.dart';
import '../../../models/assessment_attempt.dart';
import '../../../services/data_service.dart';
import '../../../widgets/stat_card.dart';

class AdminLiveTrackTab extends StatefulWidget {
  const AdminLiveTrackTab({super.key});

  @override
  State<AdminLiveTrackTab> createState() => _AdminLiveTrackTabState();
}

class _AdminLiveTrackTabState extends State<AdminLiveTrackTab> with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh UI every 3 seconds for live tracking pulse updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final attempts = dataService.attempts;
    final violations = dataService.violations;

    // Filter categories
    final cheaterAttempts = attempts.where((a) => a.isTerminated).toList();
    final activeAttempts = attempts.where((a) => a.isInProgress).toList();
    final suspiciousAttempts = attempts.where((a) => a.isInProgress && a.violationCount > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Live Radar Pulse
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sensors_rounded, color: AppTheme.dangerRed, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Live Track — Real-Time Security Portal',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.headerNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.successGreen),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE RADAR ACTIVE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor active assessment candidates in real-time and track disqualified cheaters.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),

              // Search box
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search student or GRN...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Disqualified Cheaters',
                    value: cheaterAttempts.length.toString(),
                    icon: Icons.gavel_rounded,
                    iconBgColor: AppTheme.dangerRed.withOpacity(0.15),
                    iconColor: AppTheme.dangerRed,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DISQUALIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  StatCard(
                    title: 'Live Active Candidates',
                    value: activeAttempts.length.toString(),
                    icon: Icons.play_circle_fill_rounded,
                    iconBgColor: AppTheme.surfaceBlue,
                    iconColor: AppTheme.accentBlue,
                    subtitle: '5s Heartbeat pinging',
                  ),
                  StatCard(
                    title: 'Suspicious / Warning',
                    value: suspiciousAttempts.length.toString(),
                    icon: Icons.warning_amber_rounded,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: AppTheme.warningOrange,
                    subtitle: 'Candidates with >0 violations',
                  ),
                  StatCard(
                    title: 'Total Security Events',
                    value: violations.length.toString(),
                    icon: Icons.shield_rounded,
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF7E22CE),
                    subtitle: 'Tab, blur & shortcut logs',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Live Track Tabs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.dangerRed,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.dangerRed,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gavel_rounded, color: AppTheme.dangerRed, size: 18),
                            const SizedBox(width: 8),
                            Text('🚨 Disqualified Cheater Students (${cheaterAttempts.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors_rounded, color: AppTheme.accentBlue, size: 18),
                            const SizedBox(width: 8),
                            Text('🟢 Live Active Exam Radar (${activeAttempts.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCheatersView(context, dataService, cheaterAttempts),
                        _buildActiveRadarView(context, dataService, activeAttempts),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. CHEATER STUDENTS VIEW ---

  Widget _buildCheatersView(BuildContext context, DataService dataService, List<AssessmentAttempt> cheaters) {
    final filtered = cheaters.where((a) {
      return a.grnNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.attemptId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 56),
            ),
            const SizedBox(height: 16),
            Text(
              'No Cheaters Detected',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            const SizedBox(height: 6),
            Text(
              'All students currently taking tests are adhering strictly to exam rules.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.dangerRed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: AppTheme.dangerRed, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHEATING DISQUALIFICATION WATCHLIST',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                    ),
                    Text(
                      'The candidates below attempted to cheat (tab switching, window blur, fullscreen exit) and were automatically DISQUALIFIED.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.dangerRed.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Student GRN & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Round', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cheating Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Disqualification Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Time Disqualified', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final attempt = entry.value;

                  Student? student;
                  try {
                    student = dataService.students.firstWhere(
                      (s) => s.grnNumber.toUpperCase() == attempt.grnNumber.toUpperCase(),
                    );
                  } catch (_) {
                    student = null;
                  }

                  final studentViolations = dataService.violations.where((v) => v.attemptId == attempt.attemptId).toList();
                  final violationTypes = studentViolations.map((v) => v.eventType).toSet().join(', ');

                  return DataRow(
                    cells: [
                      DataCell(Text('#$idx', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.dangerRed.withOpacity(0.15),
                              child: const Icon(Icons.person_off_rounded, color: AppTheme.dangerRed, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  attempt.grnNumber,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                                ),
                                Text(
                                  student?.name ?? 'Student ($attempt.grnNumber)',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Chip(
                          label: Text(attempt.round.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: AppTheme.surfaceBlue,
                          side: BorderSide.none,
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${attempt.violationCount} Violations Recorded',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                            Text(
                              violationTypes.isNotEmpty ? violationTypes : 'Exceeded Security Policy Limits',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DISQUALIFIED (CHEATER)',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat('MMM dd, hh:mm:ss a').format(attempt.lastHeartbeatAt),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showStudentViolationsDialog(context, dataService, attempt),
                              icon: const Icon(Icons.receipt_long_rounded, size: 16),
                              label: const Text('Audit Log'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                side: const BorderSide(color: AppTheme.primaryBlue),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmResetAttempt(context, dataService, attempt),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Admin Unlock'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. LIVE ACTIVE RADAR VIEW ---

  Widget _buildActiveRadarView(BuildContext context, DataService dataService, List<AssessmentAttempt> activeAttempts) {
    final filtered = activeAttempts.where((a) {
      return a.grnNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.attemptId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors_off_rounded, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              'No Live Assessment Sessions Active',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            const SizedBox(height: 6),
            Text(
              'No students are currently taking a test right now.',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceBlue),
          columns: const [
            DataColumn(label: Text('Live Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Student GRN & Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Assessment Round', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Warning Level', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Started At', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Last Heartbeat Ping', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((attempt) {
            Student? student;
            try {
              student = dataService.students.firstWhere(
                (s) => s.grnNumber.toUpperCase() == attempt.grnNumber.toUpperCase(),
              );
            } catch (_) {
              student = null;
            }

            final diffSeconds = DateTime.now().difference(attempt.lastHeartbeatAt).inSeconds;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: diffSeconds < 10 ? AppTheme.successGreen : AppTheme.warningOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        diffSeconds < 10 ? 'ONLINE' : 'STALE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: diffSeconds < 10 ? AppTheme.successGreen : AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        attempt.grnNumber,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                      ),
                      Text(
                        student?.name ?? 'Candidate ($attempt.grnNumber)',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(attempt.round.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.bgCanvas,
                    side: BorderSide.none,
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: attempt.violationCount == 0
                          ? AppTheme.successBg
                          : attempt.violationCount >= 2
                              ? AppTheme.dangerRed.withOpacity(0.1)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${attempt.violationCount} / 3 Warnings',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: attempt.violationCount == 0
                            ? AppTheme.successGreen
                            : attempt.violationCount >= 2
                                ? AppTheme.dangerRed
                                : AppTheme.warningOrange,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(DateFormat('hh:mm:ss a').format(attempt.startedAt))),
                DataCell(Text('${diffSeconds}s ago (${DateFormat('hh:mm:ss a').format(attempt.lastHeartbeatAt)})')),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: () => _confirmForceDisqualify(context, dataService, attempt),
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Force Disqualify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showStudentViolationsDialog(BuildContext context, DataService dataService, AssessmentAttempt attempt) {
    final studentViolations = dataService.violations.where((v) => v.attemptId == attempt.attemptId).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Cheating Violation Trail: ${attempt.grnNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: 350,
            child: studentViolations.isEmpty
                ? const Center(child: Text('No individual violations logged.'))
                : ListView.builder(
                    itemCount: studentViolations.length,
                    itemBuilder: (context, i) {
                      final v = studentViolations[i];
                      return ListTile(
                        leading: const Icon(Icons.gavel_rounded, color: AppTheme.dangerRed),
                        title: Text('${v.eventType} - ${v.details}'),
                        subtitle: Text(DateFormat('yyyy-MM-dd hh:mm:ss a').format(v.timestamp)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmForceDisqualify(BuildContext context, DataService dataService, AssessmentAttempt attempt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Force Disqualify Candidate'),
          content: Text(
            'Are you sure you want to manually disqualify candidate ${attempt.grnNumber} for cheating? This will terminate their exam immediately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
              onPressed: () async {
                await dataService.recordSecurityViolation(
                  attemptId: attempt.attemptId,
                  studentId: attempt.studentId,
                  grnNumber: attempt.grnNumber,
                  eventType: 'ADMIN_FORCE_DISQUALIFY',
                  details: 'Manually disqualified by Admin for cheating in exam.',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Candidate ${attempt.grnNumber} has been disqualified.')),
                  );
                }
              },
              child: const Text('Force Disqualify'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetAttempt(BuildContext context, DataService dataService, AssessmentAttempt attempt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Admin Unlock / Reset Attempt'),
          content: Text(
            'Are you sure you want to unlock/reset the assessment attempt for GRN ${attempt.grnNumber}? This will remove the locked attempt record and allow the candidate to restart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange, foregroundColor: Colors.white),
              onPressed: () async {
                await dataService.resetStudentAttempt(attempt.attemptId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Attempt for ${attempt.grnNumber} has been reset successfully.')),
                  );
                }
              },
              child: const Text('Reset Attempt'),
            ),
          ],
        );
      },
    );
  }
}
