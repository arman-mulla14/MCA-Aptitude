import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/student.dart';

class ExcelImportResult {
  final int totalRows;
  final int successCount;
  final int failedCount;
  final List<Student> importedStudents;
  final List<String> errors;

  ExcelImportResult({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.importedStudents,
    required this.errors,
  });
}

class ExcelImportService {
  /// Extract clean String value from Excel CellValue objects without throwing null exceptions
  static String _convertCellValueToString(dynamic cellValue) {
    if (cellValue == null) return '';
    try {
      if (cellValue is TextCellValue) {
        final span = cellValue.value;
        return span.text ?? cellValue.toString();
      }
      if (cellValue is IntCellValue) {
        return cellValue.value.toString();
      }
      if (cellValue is DoubleCellValue) {
        final double val = cellValue.value;
        if (val == val.toInt()) {
          return val.toInt().toString();
        }
        return val.toString();
      }
      if (cellValue is FormulaCellValue) {
        return cellValue.formula;
      }
      if (cellValue is BoolCellValue) {
        return cellValue.value.toString();
      }
      if (cellValue is DateCellValue) {
        return '${cellValue.year}-${cellValue.month.toString().padLeft(2, "0")}-${cellValue.day.toString().padLeft(2, "0")}';
      }
      if (cellValue is DateTimeCellValue) {
        return cellValue.asDateTimeLocal().toIso8601String();
      }
      return cellValue.toString();
    } catch (_) {
      try {
        return '$cellValue';
      } catch (e) {
        return '';
      }
    }
  }

  /// Parse bytes from an uploaded .xlsx, .xls or .csv file and extract student records
  static ExcelImportResult parseStudentFile(
    Uint8List fileBytes,
    String fileName,
    List<Student> existingStudents,
  ) {
    final List<Student> newStudents = [];
    final List<String> errors = [];
    int successCount = 0;
    int failedCount = 0;

    final Set<String> existingGrns = existingStudents.map((s) => s.grnNumber.toUpperCase().trim()).toSet();
    final Set<String> importedGrnsInCurrentBatch = {};

    List<List<String>> rows = [];
    int startRow = 0;

    try {
      if (fileName.toLowerCase().endsWith('.csv')) {
        final content = utf8.decode(fileBytes, allowMalformed: true);
        final lines = content.split(RegExp(r'\r?\n'));
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          rows.add(line.split(',').map((c) => c.trim().replaceAll('"', '')).toList());
        }
      } else {
        final excel = Excel.decodeBytes(fileBytes);
        final sheetsMap = excel.sheets;

        for (var tableName in sheetsMap.keys) {
          final sheet = sheetsMap[tableName];
          if (sheet != null) {
            for (var row in sheet.rows) {
              final rowValues = <String>[];
              for (var cell in row) {
                String cellStr = '';
                if (cell != null) {
                  try {
                    final val = cell.value;
                    if (val != null) {
                      cellStr = _convertCellValueToString(val);
                    }
                  } catch (_) {
                    cellStr = '';
                  }
                }
                rowValues.add(cellStr);
              }
              rows.add(rowValues);
            }
          }
          break; // Process primary sheet
        }
      }

      if (rows.isEmpty) {
        return ExcelImportResult(
          totalRows: 0,
          successCount: 0,
          failedCount: 0,
          importedStudents: [],
          errors: ['The selected file is empty or could not be read.'],
        );
      }

      // Find Header indices (GRN / Mobile / Name)
      int grnCol = -1;
      int mobileCol = -1;
      int nameCol = -1;

      // Scan first 5 rows to find header row (in case top rows are blank or titles)
      for (int r = 0; r < (rows.length < 5 ? rows.length : 5); r++) {
        final headerRow = rows[r].map((e) => e.toLowerCase().replaceAll(RegExp(r'[\s_]'), '')).toList();
        int foundGrn = -1;
        int foundMobile = -1;
        int foundName = -1;

        for (int i = 0; i < headerRow.length; i++) {
          final colHeader = headerRow[i];
          if (colHeader.contains('grn') || colHeader.contains('studentid') || colHeader.contains('username')) {
            foundGrn = i;
          }
          if (colHeader.contains('mobile') || colHeader.contains('phone') || colHeader.contains('contact') || colHeader.contains('password')) {
            foundMobile = i;
          }
          if (!colHeader.contains('username') && (colHeader == 'name' || colHeader.contains('studentname') || colHeader.contains('fullname') || colHeader == 'student')) {
            foundName = i;
          }
        }

        // If both GRN/Username and Mobile/Password columns identified
        if (foundGrn != -1 && foundMobile != -1) {
          grnCol = foundGrn;
          mobileCol = foundMobile;
          nameCol = foundName;
          startRow = r + 1;
          break;
        }
      }

      // Fallback: If headers not found, assume Col 0 = GRN/Username, Col 1 = Mobile/Password
      if (grnCol == -1 || mobileCol == -1) {
        grnCol = 0;
        mobileCol = 1;
        startRow = 0;
      }

      for (int r = startRow; r < rows.length; r++) {
        final row = rows[r];
        if (row.isEmpty) continue;

        final rawGrn = grnCol < row.length ? row[grnCol].trim() : '';
        final rawMobile = mobileCol < row.length ? row[mobileCol].trim() : '';
        final rawName = (nameCol != -1 && nameCol < row.length) ? row[nameCol].trim() : '';

        // Ignore completely blank rows
        if (rawGrn.isEmpty && rawMobile.isEmpty) continue;

        int rowNum = r + 1;

        // Validation Checks
        if (rawGrn.isEmpty) {
          failedCount++;
          errors.add('Row $rowNum: Username/GRN Number is blank.');
          continue;
        }

        final cleanGrn = rawGrn.toUpperCase();

        if (rawMobile.isEmpty) {
          failedCount++;
          errors.add('Row $rowNum ($cleanGrn): Password/Mobile Number is blank.');
          continue;
        }

        // Clean mobile number format (numeric only)
        final cleanMobile = rawMobile.replaceAll(RegExp(r'\D'), '');
        if (cleanMobile.length < 7) {
          failedCount++;
          errors.add('Row $rowNum ($cleanGrn): Invalid Mobile Number "$rawMobile".');
          continue;
        }

        // Check for duplicates
        if (existingGrns.contains(cleanGrn) || importedGrnsInCurrentBatch.contains(cleanGrn)) {
          failedCount++;
          errors.add('Row $rowNum ($cleanGrn): Duplicate student record detected (GRN/Username already exists).');
          continue;
        }

        importedGrnsInCurrentBatch.add(cleanGrn);

        final student = Student(
          studentId: 'STUDENT_${DateTime.now().millisecondsSinceEpoch}_$r',
          grnNumber: cleanGrn,
          mobileNumber: cleanMobile,
          name: rawName.isNotEmpty ? rawName : 'Student ($cleanGrn)',
          email: '$cleanGrn@mca.edu'.toLowerCase(),
          createdAt: DateTime.now(),
          status: 'active',
        );

        newStudents.add(student);
        successCount++;
      }
    } catch (e) {
      errors.add('File parsing error: ${e.toString()}');
    }

    return ExcelImportResult(
      totalRows: rows.isNotEmpty ? (rows.length - startRow > 0 ? rows.length - startRow : 0) : 0,
      successCount: successCount,
      failedCount: failedCount,
      importedStudents: newStudents,
      errors: errors,
    );
  }
}
