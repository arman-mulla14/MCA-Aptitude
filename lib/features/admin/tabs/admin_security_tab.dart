import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/student.dart';
import '../../../models/assessment_attempt.dart';
import '../../../services/data_service.dart';
import '../../../widgets/stat_card.dart';

class AdminSecurityTab extends StatefulWidget {
  const AdminSecurityTab({super.key});

  @override
  State<AdminSecurityTab> createState() => _AdminSecurityTabState();
}

class _AdminSecurityTabState extends State<AdminSecurityTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final policy = dataService.securityPolicy;
    final attempts = dataService.attempts;
    final violations = dataService.violations;

    final activeCount = attempts.where((a) => a.isInProgress).length;
    final terminatedAttempts = attempts.where((a) => a.isTerminated).toList();
    final terminatedCount = terminatedAttempts.length;
    final abandonedCount = attempts.where((a) => a.isAbandoned).length;
    final completedCount = attempts.where((a) => a.isCompleted).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                        child: const Icon(Icons.shield_outlined, color: AppTheme.dangerRed, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Assessment Security & Audit Hub',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.headerNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time student monitoring, cheating disqualification tracking, and security violation audit trail.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showPolicySettingsDialog(context, dataService),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Security Policy Rules'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real-time Disqualification Alert Banner
          if (terminatedCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dangerRed.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppTheme.dangerRed, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 REAL-TIME CHEATING ALERT: $terminatedCount CANDIDATE(S) DISQUALIFIED',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$terminatedCount student(s) have been automatically disqualified due to tab switches, window blur, or fullscreen exit violations.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Disqualified List'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Security Policy Summary Strip
          Card(
            color: AppTheme.surfaceBlue.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.accentBlue.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppTheme.accentBlue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Active Policy: ',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                          ),
                          TextSpan(
                            text: policy.isStrictMode ? 'STRICT MODE (AUTO-TERMINATE ON VIOLATIONS)' : 'WARNING MODE ONLY',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: policy.isStrictMode ? AppTheme.dangerRed : AppTheme.warningOrange,
                            ),
                          ),
                          TextSpan(
                            text: ' • Max Allowed Violations: ${policy.maxAllowedViolations} • Heartbeat Interval: ${policy.heartbeatIntervalSeconds}s • Stale Timeout: ${policy.heartbeatTimeoutSeconds}s',
                            style: GoogleFonts.inter(color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1100
                  ? 5
                  : constraints.maxWidth > 700
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Disqualified (Cheating)',
                    value: terminatedCount.toString(),
                    icon: Icons.gavel_rounded,
                    iconBgColor: AppTheme.dangerRed.withOpacity(0.1),
                    iconColor: AppTheme.dangerRed,
                    subtitle: 'Terminated for violations',
                  ),
                  StatCard(
                    title: 'Live Active Exam',
                    value: activeCount.toString(),
                    icon: Icons.play_circle_fill_rounded,
                    iconBgColor: AppTheme.surfaceBlue,
                    iconColor: AppTheme.accentBlue,
                    subtitle: 'Heartbeat active',
                  ),
                  StatCard(
                    title: 'Abandoned Sessions',
                    value: abandonedCount.toString(),
                    icon: Icons.timer_off_rounded,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: AppTheme.warningOrange,
                    subtitle: 'Heartbeat / timer timeout',
                  ),
                  StatCard(
                    title: 'Completed Exams',
                    value: completedCount.toString(),
                    icon: Icons.check_circle_rounded,
                    iconBgColor: AppTheme.successBg,
                    iconColor: AppTheme.successGreen,
                    subtitle: 'Submitted successfully',
                  ),
                  StatCard(
                    title: 'Total Violation Logs',
                    value: violations.length.toString(),
                    icon: Icons.report_problem_rounded,
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF7E22CE),
                    subtitle: 'Tab, blur & fullscreen events',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Tabs Card
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
                            const Icon(Icons.gavel_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('🚨 Disqualified Candidates ($terminatedCount)'),
                          ],
                        ),
                      ),
                      Tab(text: 'All Assessment Attempts (${attempts.length})'),
                      Tab(text: 'Security Violation Audit Trail (${violations.length})'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDisqualifiedView(context, dataService, terminatedAttempts),
                        _buildAttemptsView(context, dataService),
                        _buildViolationsView(context, dataService),
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

  // --- DISQUALIFIED / CHEATING CANDIDATES VIEW ---

  Widget _buildDisqualifiedView(BuildContext context, DataService dataService, List<AssessmentAttempt> terminatedAttempts) {
    if (terminatedAttempts.isEmpty) {
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
              child: const Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 56),
            ),
            const SizedBox(height: 16),
            Text(
              'No Disqualified Candidates',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
            ),
            const SizedBox(height: 6),
            Text(
              'No candidate has been terminated for security violations or cheating.',
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
            color: AppTheme.dangerRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dangerRed.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.dangerRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The candidates listed below were automatically DISQUALIFIED because they exceeded the maximum allowed security violations (e.g. switching tabs, exiting fullscreen, or opening another window).',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textDark),
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
                headingRowColor: WidgetStateProperty.all(AppTheme.dangerRed.withOpacity(0.08)),
                columns: const [
                  DataColumn(label: Text('Student GRN & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Assessment Round', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Disqualification Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Violations Recorded', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Disqualified At', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: terminatedAttempts.map((attempt) {
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
                          backgroundColor: AppTheme.surfaceBlue,
                          side: BorderSide.none,
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.block_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'DISQUALIFIED (CHEATING)',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${attempt.violationCount} Violations Logged',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                            if (violationTypes.isNotEmpty)
                              Text(
                                violationTypes,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                              ),
                          ],
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

  // --- ALL ATTEMPTS TAB VIEW ---

  Widget _buildAttemptsView(BuildContext context, DataService dataService) {
    final attempts = dataService.attempts;

    final filtered = attempts.where((a) {
      final matchesSearch = a.grnNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.attemptId.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_statusFilter == 'ALL') return matchesSearch;
      return matchesSearch && a.status.toUpperCase() == _statusFilter;
    }).toList();

    return Column(
      children: [
        // Controls Row: Search & Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by GRN Number or Attempt ID...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _statusFilter,
              onChanged: (val) {
                if (val != null) setState(() => _statusFilter = val);
              },
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                DropdownMenuItem(value: 'TERMINATED', child: Text('Disqualified / Terminated')),
                DropdownMenuItem(value: 'ABANDONED', child: Text('Abandoned')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No assessment attempts found matching criteria.',
                    style: GoogleFonts.inter(color: AppTheme.textMuted),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.bgCanvas),
                      columns: const [
                        DataColumn(label: Text('GRN Number')),
                        DataColumn(label: Text('Assessment Round')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Violations')),
                        DataColumn(label: Text('Started At')),
                        DataColumn(label: Text('Last Heartbeat')),
                        DataColumn(label: Text('Actions')),
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

                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    attempt.grnNumber,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                                  ),
                                  if (student != null)
                                    Text(
                                      student.name,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(attempt.round.toUpperCase())),
                            DataCell(_buildStatusBadge(attempt.status)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: attempt.violationCount > 0 ? AppTheme.dangerRed.withOpacity(0.1) : AppTheme.surfaceBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${attempt.violationCount} Violations',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: attempt.violationCount > 0 ? AppTheme.dangerRed : AppTheme.accentBlue,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(DateFormat('hh:mm:ss a').format(attempt.startedAt))),
                            DataCell(Text(DateFormat('hh:mm:ss a').format(attempt.lastHeartbeatAt))),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.accentBlue, size: 20),
                                    tooltip: 'View Student Violations Log',
                                    onPressed: () => _showStudentViolationsDialog(context, dataService, attempt),
                                  ),
                                  if (attempt.isTerminated || attempt.isAbandoned)
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.warningOrange, size: 20),
                                      tooltip: 'Admin Reset / Unlock Attempt',
                                      onPressed: () => _confirmResetAttempt(context, dataService, attempt),
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

  // --- VIOLATIONS TAB VIEW ---

  Widget _buildViolationsView(BuildContext context, DataService dataService) {
    final violations = dataService.violations;

    return Column(
      children: [
        Expanded(
          child: violations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Clean Security Record!',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                      ),
                      Text(
                        'No tab switches, window blur events, or fullscreen exit violations detected.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: violations.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final v = violations[violations.length - 1 - idx]; // latest first
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.dangerRed.withOpacity(0.1),
                        child: const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 20),
                      ),
                      title: Row(
                        children: [
                          Text(
                            v.grnNumber,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              v.eventType,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        v.details,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDark),
                      ),
                      trailing: Text(
                        DateFormat('MMM dd, hh:mm:ss a').format(v.timestamp),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- DIALOGS ---

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        bg = AppTheme.surfaceBlue;
        fg = AppTheme.accentBlue;
        label = 'IN PROGRESS';
        break;
      case 'COMPLETED':
        bg = AppTheme.successBg;
        fg = AppTheme.successGreen;
        label = 'COMPLETED';
        break;
      case 'TERMINATED':
        bg = AppTheme.dangerRed;
        fg = Colors.white;
        label = 'DISQUALIFIED (CHEATING)';
        break;
      case 'ABANDONED':
        bg = const Color(0xFFFEF3C7);
        fg = AppTheme.warningOrange;
        label = 'ABANDONED';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _showPolicySettingsDialog(BuildContext context, DataService dataService) {
    var policy = dataService.securityPolicy;
    bool isStrict = policy.isStrictMode;
    int maxViolations = policy.maxAllowedViolations;
    bool reqFullscreen = policy.requireFullscreen;
    bool blockDev = policy.blockDevTools;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  Text('Security Policy Rules Config', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Strict Security Mode'),
                      subtitle: const Text('Auto-terminate exam when violation threshold is reached'),
                      value: isStrict,
                      activeColor: AppTheme.dangerRed,
                      onChanged: (val) => setDialogState(() => isStrict = val),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Max Allowed Security Violations'),
                      subtitle: const Text('Number of warnings before session termination'),
                      trailing: DropdownButton<int>(
                        value: maxViolations,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => maxViolations = val);
                        },
                        items: [1, 2, 3, 5, 10]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e Violations')))
                            .toList(),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Mandatory Fullscreen Mode'),
                      subtitle: const Text('Enforce HTML5 fullscreen during assessment'),
                      value: reqFullscreen,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setDialogState(() => reqFullscreen = val),
                    ),
                    SwitchListTile(
                      title: const Text('Block Copy / Paste & Shortcuts'),
                      subtitle: const Text('Prevent right-click context menu and DevTools keys'),
                      value: blockDev,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setDialogState(() => blockDev = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    dataService.updateSecurityPolicy(
                      policy.copyWith(
                        isStrictMode: isStrict,
                        maxAllowedViolations: maxViolations,
                        requireFullscreen: reqFullscreen,
                        blockDevTools: blockDev,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security Policy configuration updated!')),
                    );
                  },
                  child: const Text('Save Security Policy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStudentViolationsDialog(BuildContext context, DataService dataService, AssessmentAttempt attempt) {
    final studentViolations = dataService.violations.where((v) => v.attemptId == attempt.attemptId).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Violation Audit Trail: ${attempt.grnNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: 350,
            child: studentViolations.isEmpty
                ? const Center(child: Text('No individual violations logged for this attempt.'))
                : ListView.builder(
                    itemCount: studentViolations.length,
                    itemBuilder: (context, i) {
                      final v = studentViolations[i];
                      return ListTile(
                        leading: const Icon(Icons.error_outline_rounded, color: AppTheme.dangerRed),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
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
