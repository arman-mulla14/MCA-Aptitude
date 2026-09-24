import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../../../core/theme/app_theme.dart';
import '../../../models/student.dart';
import '../../../services/data_service.dart';
import '../../../services/excel_import_service.dart';

class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  String _searchQuery = '';
  String _selectedAssessmentRound = 'ALL';
  ExcelImportResult? _lastImportResult;
  bool _isImporting = false;
  int _currentPage = 0;
  int _rowsPerPage = 15;

  void _handlePickAndImportExcel() async {
    setState(() {
      _isImporting = true;
      _lastImportResult = null;
    });

    try {
      final pickedFiles = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (pickedFiles != null && pickedFiles.files.isNotEmpty) {
        final file = pickedFiles.files.first;
        final Uint8List? bytes = file.bytes;
        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file bytes.')),
          );
          return;
        }

        final dataService = Provider.of<DataService>(context, listen: false);
        final result = ExcelImportService.parseStudentFile(
          bytes,
          file.name,
          dataService.students,
        );

        if (result.importedStudents.isNotEmpty) {
          final err = await dataService.addStudents(result.importedStudents);
          if (mounted) {
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Firebase Note: $err\nPlease enable Firestore Security Rules to allow read/write.'),
                  backgroundColor: AppTheme.warningOrange,
                  duration: const Duration(seconds: 6),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Saved ${result.importedStudents.length} student records directly to Firebase ("students" collection)!'),
                  backgroundColor: AppTheme.successGreen,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }

        setState(() {
          _lastImportResult = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File upload error: ${e.toString()}'), backgroundColor: AppTheme.dangerRed),
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _showAddStudentDialog() {
    final grnController = TextEditingController();
    final mobileController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Student Manually', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: grnController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'GRN Number', hintText: 'e.g. GRN005'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number', hintText: 'e.g. 9876543219'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Student Full Name (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grn = grnController.text.trim().toUpperCase();
              final mobile = mobileController.text.trim();
              if (grn.isEmpty || mobile.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GRN and Mobile Number are required.')),
                );
                return;
              }

              final dataService = Provider.of<DataService>(context, listen: false);
              if (dataService.students.any((s) => s.grnNumber.toUpperCase() == grn)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('GRN $grn already exists!')),
                );
                return;
              }

              final student = Student(
                studentId: 'STUDENT_${DateTime.now().millisecondsSinceEpoch}',
                grnNumber: grn,
                mobileNumber: mobile,
                name: nameController.text.trim(),
              );

              await dataService.addStudents([student]);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Student $grn created successfully!'), backgroundColor: AppTheme.successGreen),
              );
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);

    final filteredStudents = dataService.students.where((s) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = s.grnNumber.toLowerCase().contains(query) || s.name.toLowerCase().contains(query) || s.mobileNumber.contains(query);
      if (!matchesSearch) return false;

      if (_selectedAssessmentRound != 'ALL') {
        final isRegistered = dataService.isStudentRegisteredForAssessment(s.grnNumber, _selectedAssessmentRound);
        if (!isRegistered) return false;
      }

      return true;
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
                    'Student Account Management',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Import student records from Excel/CSV files or add them manually',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  if (dataService.students.isNotEmpty) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear All Students?'),
                            content: const Text('Are you sure you want to delete all student records? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await dataService.clearAllStudents();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All student records cleared!')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                                child: const Text('Delete All'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: AppTheme.dangerRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _showAddStudentDialog,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Student'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : _handlePickAndImportExcel,
                    icon: _isImporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(_isImporting ? 'Parsing File...' : 'Upload Excel / CSV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Import Results Summary Card if file was just parsed
          if (_lastImportResult != null) ...[
            Card(
              color: _lastImportResult!.failedCount == 0 ? AppTheme.successBg : AppTheme.warningBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _lastImportResult!.failedCount == 0 ? AppTheme.successGreen : AppTheme.warningOrange,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _lastImportResult!.failedCount == 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: _lastImportResult!.failedCount == 0 ? AppTheme.successGreen : AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Excel Import Summary',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildImportStatBadge('Total Rows', _lastImportResult!.totalRows.toString(), AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        _buildImportStatBadge('Successfully Imported', _lastImportResult!.successCount.toString(), AppTheme.successGreen),
                        const SizedBox(width: 12),
                        _buildImportStatBadge('Failed / Invalid', _lastImportResult!.failedCount.toString(), AppTheme.dangerRed),
                      ],
                    ),
                    if (_lastImportResult!.errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Validation Report & Error Log:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _lastImportResult!.errors.length,
                          itemBuilder: (context, idx) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${_lastImportResult!.errors[idx]}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.dangerRed),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Search Bar & Table Header
          Builder(
            builder: (context) {
              final startIndex = _currentPage * _rowsPerPage;
              final endIndex = (startIndex + _rowsPerPage < filteredStudents.length)
                  ? startIndex + _rowsPerPage
                  : filteredStudents.length;
              final pageItems = (startIndex < filteredStudents.length)
                  ? filteredStudents.sublist(startIndex, endIndex)
                  : <Student>[];
              final totalPages = (filteredStudents.length / _rowsPerPage).ceil();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              onChanged: (val) => setState(() {
                                _searchQuery = val;
                                _currentPage = 0;
                              }),
                              decoration: const InputDecoration(
                                hintText: 'Search by GRN Number, Student Name, or Mobile Number...',
                                prefixIcon: Icon(Icons.search_rounded),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedAssessmentRound,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Assessment Filter',
                                isDense: true,
                                prefixIcon: Icon(Icons.assignment_ind_rounded, color: AppTheme.accentBlue),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text('All Students (${dataService.students.length})', overflow: TextOverflow.ellipsis),
                                ),
                                ...dataService.assessments.map((a) {
                                  final count = a.registeredStudentGrns.isEmpty || a.registeredStudentGrns.contains('ALL')
                                      ? dataService.students.length
                                      : a.registeredStudentGrns.length;
                                  return DropdownMenuItem(
                                    value: a.round,
                                    child: Text('${a.title} ($count Reg.)', overflow: TextOverflow.ellipsis),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredStudents.length} Students',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Data Table
                      filteredStudents.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No student records found.',
                                style: GoogleFonts.inter(color: AppTheme.textMuted),
                              ),
                            )
                          : Column(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.surfaceBlue),
                                    columnSpacing: 22,
                                    horizontalMargin: 16,
                                    columns: const [
                                      DataColumn(label: Text('GRN Number', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Mobile (Credential)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Created Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: pageItems.map((student) {
                                      return DataRow(cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              const Icon(Icons.badge_outlined, size: 16, color: AppTheme.accentBlue),
                                              const SizedBox(width: 8),
                                              Text(student.grnNumber, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(student.name.isNotEmpty ? student.name : 'MCA Student')),
                                        DataCell(Text(student.mobileNumber)),
                                        DataCell(Text(student.email)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successBg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              student.status.toUpperCase(),
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 20),
                                            onPressed: () async {
                                              await dataService.deleteStudent(student.grnNumber);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Deleted student ${student.grnNumber}')),
                                                );
                                              }
                                            },
                                            tooltip: 'Delete Student',
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Pagination Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing ${startIndex + 1} - $endIndex of ${filteredStudents.length} Students',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                                    ),
                                    Row(
                                      children: [
                                        Text('Rows per page: ', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                                        const SizedBox(width: 6),
                                        DropdownButton<int>(
                                          value: _rowsPerPage,
                                          underline: const SizedBox(),
                                          items: [10, 15, 25, 50, 100].map((int val) {
                                            return DropdownMenuItem<int>(
                                              value: val,
                                              child: Text('$val', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _rowsPerPage = val;
                                                _currentPage = 0;
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left_rounded),
                                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                          tooltip: 'Previous Page',
                                        ),
                                        Text(
                                          '${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right_rounded),
                                          onPressed: (_currentPage + 1) < totalPages ? () => setState(() => _currentPage++) : null,
                                          tooltip: 'Next Page',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
