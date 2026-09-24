import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/result.dart';
import '../../../services/data_service.dart';

class AdminResultsTab extends StatefulWidget {
  const AdminResultsTab({super.key});

  @override
  State<AdminResultsTab> createState() => _AdminResultsTabState();
}

class _AdminResultsTabState extends State<AdminResultsTab> {
  String _searchQuery = '';
  String _selectedRoundFilter = 'ALL'; // 'ALL', 'gd', 'technical'
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'PASSED', 'FAILED'

  void _showResultDetailsModal(AssessmentResult result) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final roundQuestions = dataService.getQuestionsForRound(result.round);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
            ),
            const SizedBox(width: 10),
            Text(
              'Submission Detail — ${result.grnNumber}',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student: ${result.studentName}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: result.isPassed ? AppTheme.successBg : AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Round: ${result.round.toUpperCase()} • Score: ${result.obtainedMarks} / ${result.totalMarks} (Passing: ${result.passingMarks})',
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                ),
                const Divider(height: 24),
                Text('Answers Breakdown:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ...roundQuestions.map((q) {
                  final selectedOpt = result.answersMap[q.questionId] ?? 'Not Answered';
                  final isCorrect = selectedOpt.trim().toUpperCase().startsWith(q.correctAnswer.toUpperCase());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCanvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${q.order}. ${q.questionText}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Selected: ', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                            Text(
                              selectedOpt,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? AppTheme.successGreen : AppTheme.dangerRed,
                              ),
                            ),
                            const Spacer(),
                            Text('Correct Answer: ', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                            Text(
                              'Option ${q.correctAnswer}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final results = dataService.results;

    final filteredResults = results.where((r) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = r.grnNumber.toLowerCase().contains(query) || r.studentName.toLowerCase().contains(query);

      final matchesRound = _selectedRoundFilter == 'ALL' || r.round.toLowerCase() == _selectedRoundFilter.toLowerCase();
      final matchesStatus = _selectedStatusFilter == 'ALL' ||
          (_selectedStatusFilter.toUpperCase().startsWith('PASS') && r.isPassed) ||
          (_selectedStatusFilter.toUpperCase().startsWith('FAIL') && !r.isPassed);

      return matchesQuery && matchesRound && matchesStatus;
    }).toList();

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
                    'Student Results & Evaluation Management',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track student scores for GD and Technical rounds with automatic pass/fail evaluation',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Filter Controls Bar
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search student name or GRN...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Round Filter Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoundFilter,
                          decoration: const InputDecoration(labelText: 'Filter Round'),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Assessment Rounds')),
                            DropdownMenuItem(value: AppConstants.roundGD, child: Text('GD Round')),
                            DropdownMenuItem(value: AppConstants.roundTechnical, child: Text('Technical Round')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRoundFilter = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status Filter Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatusFilter,
                          decoration: const InputDecoration(labelText: 'Filter Status'),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Result Statuses')),
                            DropdownMenuItem(value: 'PASSED', child: Text('PASSED Only')),
                            DropdownMenuItem(value: 'FAILED', child: Text('FAILED Only')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatusFilter = val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Results Table
                  filteredResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'No result records found matching your filters.',
                            style: GoogleFonts.inter(color: AppTheme.textMuted),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceBlue),
                            columns: const [
                              DataColumn(label: Text('GRN Number', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Round Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Obtained / Total Score', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Passing Threshold', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Result Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredResults.map((result) {
                              return DataRow(cells: [
                                DataCell(
                                  Text(result.grnNumber, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                ),
                                DataCell(Text(result.studentName.isNotEmpty ? result.studentName : 'Student (${result.grnNumber})')),
                                DataCell(
                                  Text(
                                    result.round == AppConstants.roundGD ? 'Round 1 (GD)' : 'Round 2 (Technical)',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${result.obtainedMarks} / ${result.totalMarks}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataCell(Text('${result.passingMarks} Marks')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: result.isPassed ? AppTheme.successBg : AppTheme.dangerBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      result.status.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: result.isPassed ? AppTheme.successGreen : AppTheme.dangerRed,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, color: AppTheme.accentBlue),
                                    onPressed: () => _showResultDetailsModal(result),
                                    tooltip: 'View Answer Breakdown',
                                  ),
                                ),
                              ]);
                            }).toList(),
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
}
