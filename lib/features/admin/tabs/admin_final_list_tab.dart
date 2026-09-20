import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/student.dart';
import '../../../models/assessment.dart';
import '../../../services/data_service.dart';
import '../../../services/certificate_pdf_service.dart';
import '../../../widgets/certificate_preview_widget.dart';

class AdminFinalListTab extends StatefulWidget {
  const AdminFinalListTab({super.key});

  @override
  State<AdminFinalListTab> createState() => _AdminFinalListTabState();
}

class _AdminFinalListTabState extends State<AdminFinalListTab> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All' | 'Selected' | 'Passed Both' | 'Pending'
  String _selectedAssessmentRound = 'ALL'; // 'ALL' or specific round
  int _currentPage = 0;
  int _rowsPerPage = 15;

  void _showCertificateModal(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Appreciation Certificate Preview',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 1000,
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
                      label: const Text('Generate & Download PDF'),
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
    final dataService = Provider.of<DataService>(context);
    final allStudents = dataService.students;
    final assessments = dataService.assessments;

    // Filter students by selected assessment registration
    final targetStudents = _selectedAssessmentRound == 'ALL'
        ? allStudents
        : allStudents.where((s) => dataService.isStudentRegisteredForAssessment(s.grnNumber, _selectedAssessmentRound)).toList();

    // Apply Status Filter & Search Query
    final filteredStudents = targetStudents.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.grnNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Selected') {
        return s.certificateEligible || s.finalStatus == 'SELECTED';
      } else if (_selectedFilter == 'Passed Both') {
        return s.gdStatus == 'PASS' && s.technicalStatus == 'PASS';
      } else if (_selectedFilter == 'Pending') {
        return s.finalStatus == 'PENDING';
      }

      return true;
    }).toList();

    // Dynamic Stats for selected Assessment cohort
    final totalCount = targetStudents.length;
    final selectedCount = targetStudents.where((s) => s.certificateEligible || s.finalStatus == 'SELECTED').length;
    final passedBothCount = targetStudents.where((s) => s.gdStatus == 'PASS' && s.technicalStatus == 'PASS').length;

    // Pagination
    final totalPages = (filteredStudents.isEmpty) ? 1 : (filteredStudents.length / _rowsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = 0;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage > filteredStudents.length)
        ? filteredStudents.length
        : startIndex + _rowsPerPage;

    final pagedStudents = filteredStudents.isEmpty
        ? <Student>[]
        : filteredStudents.sublist(startIndex, endIndex);

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
                    'Final Candidates & Certificate List',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review candidate round evaluations, approve certificate eligibility and download certificates',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Banner Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: _selectedAssessmentRound == 'ALL' ? 'Total Candidates' : 'Registered Candidates',
                  value: '$totalCount',
                  icon: Icons.people_alt_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Certificate Eligible',
                  value: '$selectedCount',
                  icon: Icons.workspace_premium_rounded,
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Passed Both Rounds',
                  value: '$passedBothCount',
                  icon: Icons.verified_rounded,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Controls Bar (Search + Assessment Dropdown + Status Filter)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Search TextField
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by Student Name or GRN Number...',
                            prefixIcon: Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() {
                            _searchQuery = val;
                            _currentPage = 0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Assessment Selector Dropdown (Filters only registered students for selected assessment)
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedAssessmentRound,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Assessment Round',
                            isDense: true,
                            prefixIcon: Icon(Icons.assignment_ind_rounded, color: AppTheme.accentBlue),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text('All Assessment Rounds (${allStudents.length} Students)', overflow: TextOverflow.ellipsis),
                            ),
                            ...assessments.map((a) {
                              final regCount = a.registeredStudentGrns.isEmpty || a.registeredStudentGrns.contains('ALL')
                                  ? allStudents.length
                                  : a.registeredStudentGrns.length;
                              return DropdownMenuItem(
                                value: a.round,
                                child: Text(
                                  '${a.title} ($regCount Registered)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAssessmentRound = val;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status Filter Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status Filter',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Students')),
                            DropdownMenuItem(value: 'Selected', child: Text('Eligible / Selected')),
                            DropdownMenuItem(value: 'Passed Both', child: Text('Passed Both Rounds')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending Approval')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFilter = val;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_selectedAssessmentRound != 'ALL') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.accentBlue, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Showing registered students for: ${assessments.firstWhere((a) => a.round.toLowerCase() == _selectedAssessmentRound.toLowerCase(), orElse: () => Assessment(assessmentId: '', title: _selectedAssessmentRound.toUpperCase(), round: _selectedAssessmentRound, totalMarks: 0, passingMarks: 0)).title} ($totalCount Students Registered)',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.headerNavy),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _selectedAssessmentRound = 'ALL'),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Final List Data Table Card
          Card(
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('GRN Number', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('GD Round', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Technical Round', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Final Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Certificate Eligibility', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedStudents.asMap().entries.map((entry) {
                      final idx = startIndex + entry.key + 1;
                      final s = entry.value;
                      final isEligible = s.certificateEligible || s.finalStatus == 'SELECTED';

                      return DataRow(
                        cells: [
                          DataCell(Text('$idx')),
                          DataCell(Text(
                            s.name.isNotEmpty ? s.name : 'Student (${s.grnNumber})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(s.grnNumber)),
                          DataCell(_buildStatusBadge(s.gdStatus)),
                          DataCell(_buildStatusBadge(s.technicalStatus)),
                          DataCell(_buildFinalStatusBadge(s.finalStatus)),
                          DataCell(
                            Switch(
                              value: isEligible,
                              activeColor: AppTheme.successGreen,
                              onChanged: (val) async {
                                await dataService.updateStudentCertificateEligibility(
                                  grnNumber: s.grnNumber,
                                  isEligible: val,
                                  finalStatus: val ? 'SELECTED' : 'PENDING',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val ? 'Certificate enabled for ${s.name}!' : 'Certificate revoked for ${s.name}.'),
                                      backgroundColor: val ? AppTheme.successGreen : AppTheme.warningOrange,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_rounded, color: AppTheme.accentBlue),
                                  tooltip: 'Preview Certificate',
                                  onPressed: () => _showCertificateModal(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
                                  tooltip: 'Generate PDF',
                                  onPressed: () async {
                                    await CertificatePdfService.printOrShareCertificate(s);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, color: AppTheme.successGreen),
                                  tooltip: 'Send Certificate',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Certificate notification sent to ${s.name}!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // Pagination Footer Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${filteredStudents.isEmpty ? 0 : startIndex + 1} - $endIndex of ${filteredStudents.length} Students',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                          ),
                          Text('Page ${_currentPage + 1} of $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppTheme.bgCanvas;
    Color fg = AppTheme.textMuted;

    if (status == 'PASS') {
      bg = AppTheme.successBg;
      fg = AppTheme.successGreen;
    } else if (status == 'FAIL') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildFinalStatusBadge(String status) {
    Color bg = AppTheme.bgCanvas;
    Color fg = AppTheme.textMuted;

    if (status == 'SELECTED') {
      bg = AppTheme.successBg;
      fg = AppTheme.successGreen;
    } else if (status == 'REJECTED') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerRed;
    } else {
      bg = AppTheme.surfaceBlue;
      fg = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
