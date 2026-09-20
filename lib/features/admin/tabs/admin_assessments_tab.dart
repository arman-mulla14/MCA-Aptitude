import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/assessment.dart';
import '../../../models/question.dart';
import '../../../services/data_service.dart';

class AdminAssessmentsTab extends StatefulWidget {
  const AdminAssessmentsTab({super.key});

  @override
  State<AdminAssessmentsTab> createState() => _AdminAssessmentsTabState();
}

class _AdminAssessmentsTabState extends State<AdminAssessmentsTab> {
  void _showAddRoundDialog() {
    final titleController = TextEditingController();
    final passingMarksController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create New Assessment Round', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a custom assessment round (e.g., Aptitude, Logical Reasoning, HR Round, Coding Challenge).'),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Round Title',
                hintText: 'e.g. Round 3 — HR Assessment Round',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passingMarksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Passing Marks Threshold',
                hintText: 'e.g. 3',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final passing = int.tryParse(passingMarksController.text.trim()) ?? 3;

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title for the new round.')),
                );
                return;
              }

              final dataService = Provider.of<DataService>(context, listen: false);
              final roundKey = 'round_${dataService.assessments.length + 1}_${DateTime.now().millisecondsSinceEpoch % 10000}';

              final newAssessment = Assessment(
                assessmentId: 'ASSESSMENT_${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                round: roundKey,
                passingMarks: passing,
                totalMarks: 0,
                isActive: true,
              );

              await dataService.addAssessment(newAssessment);
              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('New round "$title" created successfully!'), backgroundColor: AppTheme.successGreen),
                );
              }
            },
            child: const Text('Create Round'),
          ),
        ],
      ),
    );
  }

  void _showPassingMarksDialog(String round, int currentMarks, String roundTitle) {
    final controller = TextEditingController(text: currentMarks.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configure Passing Marks', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set the minimum score required to pass "$roundTitle".'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Passing Marks',
                hintText: 'e.g. 3',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newMarks = int.tryParse(controller.text.trim());
              if (newMarks != null && newMarks > 0) {
                final dataService = Provider.of<DataService>(context, listen: false);
                await dataService.updateAssessmentPassingMarks(round, newMarks);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passing marks updated to $newMarks!'), backgroundColor: AppTheme.successGreen),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// FAST REGISTER / ASSIGN STUDENTS TO ASSESSMENT ROUND MODAL
  void _showAssignStudentsDialog(String round, Assessment assessment) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final allStudents = dataService.students;

    final Set<String> selectedGrns = Set<String>.from(assessment.registeredStudentGrns);
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStudents = allStudents.where((s) {
              final q = searchQuery.toLowerCase();
              return s.name.toLowerCase().contains(q) || s.grnNumber.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.how_to_reg_rounded, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assign & Register Students: ${assessment.title}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Only registered students will be allowed to log in or join this assessment round.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Fast 1-Click Action Toolbar
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              selectedGrns.clear();
                              selectedGrns.addAll(allStudents.map((s) => s.grnNumber.toUpperCase()));
                            });
                          },
                          icon: const Icon(Icons.flash_on_rounded, size: 16),
                          label: const Text('Register All Students (Fast 1-Click)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              selectedGrns.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Clear All'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerRed,
                            side: const BorderSide(color: AppTheme.dangerRed),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Input & Count Badge
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setModalState(() => searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by Student Name or GRN...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${selectedGrns.length} / ${allStudents.length} Selected',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.accentBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Student Checkbox List
                    Expanded(
                      child: allStudents.isEmpty
                          ? Center(
                              child: Text(
                                'No student records found. Upload Excel in Student Records tab first.',
                                style: GoogleFonts.inter(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredStudents.length,
                              separatorBuilder: (c, i) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final s = filteredStudents[idx];
                                final grn = s.grnNumber.toUpperCase();
                                final isChecked = selectedGrns.contains(grn);

                                return CheckboxListTile(
                                  value: isChecked,
                                  activeColor: AppTheme.primaryBlue,
                                  title: Text(
                                    s.name.isEmpty ? 'Student ($grn)' : s.name,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Text('GRN: $grn • Mobile: ${s.mobileNumber}'),
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        selectedGrns.add(grn);
                                      } else {
                                        selectedGrns.remove(grn);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton.icon(
                  onPressed: () async {
                    await dataService.updateAssessmentRegisteredStudents(round, selectedGrns.toList());
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${selectedGrns.length} students registered for "${assessment.title}"!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Save Registered Students'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuestionModal({Question? existingQuestion, required String round, required String roundTitle}) {
    final qTextController = TextEditingController(text: existingQuestion?.questionText ?? '');
    final optAController = TextEditingController(text: (existingQuestion != null && existingQuestion.options.isNotEmpty) ? existingQuestion.options[0] : '');
    final optBController = TextEditingController(text: (existingQuestion != null && existingQuestion.options.length > 1) ? existingQuestion.options[1] : '');
    final optCController = TextEditingController(text: (existingQuestion != null && existingQuestion.options.length > 2) ? existingQuestion.options[2] : '');
    final optDController = TextEditingController(text: (existingQuestion != null && existingQuestion.options.length > 3) ? existingQuestion.options[3] : '');

    final marksController = TextEditingController(text: (existingQuestion?.marks ?? 1).toString());
    final orderController = TextEditingController(text: (existingQuestion?.order ?? 1).toString());

    String selectedCorrectAnswer = existingQuestion?.correctAnswer ?? 'A';
    if (!['A', 'B', 'C', 'D'].contains(selectedCorrectAnswer)) {
      selectedCorrectAnswer = 'A';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            existingQuestion != null ? 'Edit MCQ Question' : 'Add Question to "$roundTitle"',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: qTextController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Question Text',
                      hintText: 'Enter question text here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('MCQ Options', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: optAController,
                    decoration: const InputDecoration(labelText: 'Option A', prefixIcon: Icon(Icons.looks_one_outlined)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: optBController,
                    decoration: const InputDecoration(labelText: 'Option B', prefixIcon: Icon(Icons.looks_two_outlined)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: optCController,
                    decoration: const InputDecoration(labelText: 'Option C', prefixIcon: Icon(Icons.looks_3_outlined)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: optDController,
                    decoration: const InputDecoration(labelText: 'Option D', prefixIcon: Icon(Icons.looks_4_outlined)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCorrectAnswer,
                          decoration: const InputDecoration(labelText: 'Correct Option Answer'),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('Option A')),
                            DropdownMenuItem(value: 'B', child: Text('Option B')),
                            DropdownMenuItem(value: 'C', child: Text('Option C')),
                            DropdownMenuItem(value: 'D', child: Text('Option D')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCorrectAnswer = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: marksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Marks (Score)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: orderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Display Order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final text = qTextController.text.trim();
                final optA = optAController.text.trim();
                final optB = optBController.text.trim();
                final optC = optCController.text.trim();
                final optD = optDController.text.trim();
                final marks = int.tryParse(marksController.text.trim()) ?? 1;
                final order = int.tryParse(orderController.text.trim()) ?? 1;

                if (text.isEmpty || optA.isEmpty || optB.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill question text and at least options A and B.')),
                  );
                  return;
                }

                final dataService = Provider.of<DataService>(context, listen: false);
                final assessment = dataService.getAssessmentByRound(round);

                final question = Question(
                  questionId: existingQuestion?.questionId ?? 'Q_${round.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}',
                  assessmentId: assessment?.assessmentId ?? 'ASSESSMENT_${round.toUpperCase()}',
                  round: round,
                  questionText: text,
                  options: [
                    optA.startsWith('A.') ? optA : 'A. $optA',
                    optB.startsWith('B.') ? optB : 'B. $optB',
                    if (optC.isNotEmpty) (optC.startsWith('C.') ? optC : 'C. $optC'),
                    if (optD.isNotEmpty) (optD.startsWith('D.') ? optD : 'D. $optD'),
                  ],
                  correctAnswer: selectedCorrectAnswer,
                  marks: marks,
                  order: order,
                  isActive: true,
                );

                if (existingQuestion != null) {
                  await dataService.updateQuestion(question);
                } else {
                  await dataService.addQuestion(question);
                }

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existingQuestion != null ? 'Question updated!' : 'Question added!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Save Question'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final assessments = dataService.assessments;

    if (assessments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showAddRoundDialog,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add First Assessment Round'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: assessments.length,
      child: SingleChildScrollView(
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
                      'Assessment & Question Management',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure round passing criteria, register authorized students, add MCQs and edit marks',
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddRoundDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add New Round'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs Header for all Assessment Rounds
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TabBar(
                isScrollable: assessments.length > 3,
                indicatorColor: AppTheme.accentBlue,
                labelColor: AppTheme.accentBlue,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: assessments.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final a = entry.value;
                  final roundQuestions = dataService.getQuestionsForRound(a.round);
                  return Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            idx == 1 ? Icons.groups_rounded : (idx == 2 ? Icons.code_rounded : Icons.psychology_rounded),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text('Round $idx — ${a.title} (${roundQuestions.length} Qs)'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 680,
              child: TabBarView(
                children: assessments.asMap().entries.map((entry) {
                  final a = entry.value;
                  final roundQuestions = dataService.getQuestionsForRound(a.round);
                  return _buildRoundView(
                    round: a.round,
                    assessment: a,
                    questions: roundQuestions,
                    canDeleteRound: assessments.length > 1,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundView({
    required String round,
    required Assessment assessment,
    required List<Question> questions,
    required bool canDeleteRound,
  }) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final regCount = assessment.registeredStudentGrns.length;
    final totalStudents = dataService.students.length;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Round Configuration Header Card
          Card(
            color: AppTheme.surfaceBlue,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: AppTheme.accentBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.title,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Questions: ${questions.length} • Total Marks: ${assessment.totalMarks} • Passing Score: ${assessment.passingMarks} Marks',
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: regCount > 0 ? AppTheme.successBg : AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: regCount > 0 ? AppTheme.successGreen : AppTheme.borderColor),
                          ),
                          child: Text(
                            regCount == 0 ? '👥 Registered Students: All ($totalStudents)' : '👥 Registered Students: $regCount / $totalStudents Authorized',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: regCount > 0 ? AppTheme.successGreen : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button 1: Assign Students
                  ElevatedButton.icon(
                    onPressed: () => _showAssignStudentsDialog(round, assessment),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Register Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Button 2: Set Passing Marks
                  OutlinedButton.icon(
                    onPressed: () => _showPassingMarksDialog(round, assessment.passingMarks, assessment.title),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Set Passing Marks'),
                  ),
                  const SizedBox(width: 10),

                  // Button 3: Add Question
                  ElevatedButton.icon(
                    onPressed: () => _showQuestionModal(round: round, roundTitle: assessment.title),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Question'),
                  ),

                  if (canDeleteRound) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.dangerRed),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Assessment Round?'),
                            content: Text('Are you sure you want to delete "${assessment.title}" and all its questions?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await dataService.deleteAssessment(assessment.assessmentId);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Deleted "${assessment.title}"')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                                child: const Text('Delete Round'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Delete Round',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Questions List
          questions.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No questions created for this round yet. Click "Add Question" to begin.',
                        style: GoogleFonts.inter(color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (context, idx) {
                    final q = questions[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Question ${q.order} • ${q.marks} Mark${q.marks > 1 ? "s" : ""}',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.accentBlue, size: 20),
                                      onPressed: () => _showQuestionModal(existingQuestion: q, round: round, roundTitle: assessment.title),
                                      tooltip: 'Edit Question',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 20),
                                      onPressed: () async {
                                        await dataService.deleteQuestion(q.questionId);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Question deleted.')),
                                          );
                                        }
                                      },
                                      tooltip: 'Delete Question',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              q.questionText,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.headerNavy),
                            ),
                            const SizedBox(height: 14),

                            // Display Options List
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: q.options.map((opt) {
                                final isCorrect = opt.toUpperCase().startsWith(q.correctAnswer.toUpperCase());
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCorrect ? AppTheme.successBg : AppTheme.bgCanvas,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCorrect ? AppTheme.successGreen : AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isCorrect ? FontWeight.bold : FontWeight.w500,
                                      color: isCorrect ? AppTheme.successGreen : AppTheme.textDark,
                                    ),
                                  ),
                                );
                              }).toList(),
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
}
