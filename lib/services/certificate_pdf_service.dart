import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student.dart';

class CertificatePdfService {
  /// Generate A4 Landscape PDF Document using high-performance parallel asset loading
  static Future<Uint8List> generateCertificatePdf(Student student) async {
    final pdf = pw.Document();

    pw.MemoryImage? abhijeetSig;
    pw.MemoryImage? armanSig;

    // Load Fonts in parallel for maximum speed
    final fontResults = await Future.wait([
      PdfGoogleFonts.interRegular(),
      PdfGoogleFonts.interSemiBold(),
      PdfGoogleFonts.interBold(),
      PdfGoogleFonts.merriweatherBlack(),
      PdfGoogleFonts.greatVibesRegular(),
    ]);

    final interRegular = fontResults[0];
    final interSemiBold = fontResults[1];
    final interBold = fontResults[2];
    final merriweatherBlack = fontResults[3];
    final greatVibes = fontResults[4];

    // Load Transparent PNG Signatures in parallel
    try {
      final results = await Future.wait([
        rootBundle.load('assets/signatures/abhijeet_signature.png'),
        rootBundle.load('assets/signatures/arman_signature.png'),
      ]);
      abhijeetSig = pw.MemoryImage(results[0].buffer.asUint8List());
      armanSig = pw.MemoryImage(results[1].buffer.asUint8List());
    } catch (_) {
      try {
        final resultsJpg = await Future.wait([
          rootBundle.load('assets/signatures/abhijeet_signature.jpg'),
          rootBundle.load('assets/signatures/arman_signature.jpg'),
        ]);
        abhijeetSig = pw.MemoryImage(resultsJpg[0].buffer.asUint8List());
        armanSig = pw.MemoryImage(resultsJpg[1].buffer.asUint8List());
      } catch (_) {}
    }

    final rawStudentName = student.name.isNotEmpty ? student.name : 'Student (${student.grnNumber})';
    final studentName = _formatTitleCase(rawStudentName);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          final double w = PdfPageFormat.a4.landscape.width;
          final double h = PdfPageFormat.a4.landscape.height;

          return pw.Container(
            padding: const pw.EdgeInsets.all(16), // Outer margin
            color: PdfColors.white,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#0F172A'), width: 3.5), // Outer deep navy border
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(6), // Space between double borders
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 1.5), // Inner metallic gold border
                ),
                child: pw.Stack(
                  children: [
                    // Corner Deco Top Left
                    pw.Positioned(top: 0, left: 0, child: _buildCornerDeco(true, true)),
                    // Corner Deco Top Right
                    pw.Positioned(top: 0, right: 0, child: _buildCornerDeco(true, false)),
                    // Corner Deco Bottom Left
                    pw.Positioned(bottom: 30, left: 0, child: _buildCornerDeco(false, true)),
                    // Corner Deco Bottom Right
                    pw.Positioned(bottom: 30, right: 0, child: _buildCornerDeco(false, false)),

                    // Main Content Column
                    pw.Positioned.fill(
                      bottom: 30, // Space for footer
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          // Gold Badge Icon
                          pw.Container(
                            width: 46,
                            height: 46,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColor.fromHex('#0F172A'),
                              border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 2), // Gold accent
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '★',
                                style: pw.TextStyle(
                                  font: interBold,
                                  fontSize: 22,
                                  color: PdfColor.fromHex('#D4AF37'),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: h * 0.02),

                          // Subheader
                          pw.Text(
                            'DEPARTMENT OF MASTER OF COMPUTER APPLICATIONS',
                            style: pw.TextStyle(
                              font: interBold,
                              fontSize: w * 0.012,
                              color: PdfColor.fromHex('#475569'),
                              letterSpacing: 2,
                            ),
                          ),
                          pw.SizedBox(height: h * 0.008),

                          // Title
                          pw.Text(
                            'CERTIFICATE OF APPRECIATION',
                            style: pw.TextStyle(
                              font: merriweatherBlack,
                              fontSize: w * 0.038,
                              color: PdfColor.fromHex('#0F172A'),
                              letterSpacing: 4,
                            ),
                          ),
                          pw.SizedBox(height: h * 0.008),

                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(width: w * 0.12, height: 1.5, color: PdfColor.fromHex('#D4AF37')),
                              pw.SizedBox(width: 10),
                              pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 8, color: PdfColor.fromHex('#D4AF37'))),
                              pw.SizedBox(width: 10),
                              pw.Container(width: w * 0.12, height: 1.5, color: PdfColor.fromHex('#D4AF37')),
                            ],
                          ),
                          pw.SizedBox(height: h * 0.035),

                          // Subtitle
                          pw.Text(
                            'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                            style: pw.TextStyle(
                              font: interBold,
                              fontSize: w * 0.012,
                              color: PdfColor.fromHex('#1D4ED8'), // Royal Blue
                              letterSpacing: 2.5,
                            ),
                          ),
                          pw.SizedBox(height: h * 0.015),

                          // Dynamic Student Name (Title Case & Single Line)
                          pw.SizedBox(
                            width: w * 0.65,
                            child: pw.FittedBox(
                              fit: pw.BoxFit.scaleDown,
                              child: pw.Text(
                                studentName,
                                maxLines: 1,
                                style: pw.TextStyle(
                                  font: greatVibes,
                                  fontSize: w * 0.056,
                                  color: PdfColor.fromHex('#0F172A'),
                                ),
                              ),
                            ),
                          ),
                          pw.Container(
                            width: w * 0.38,
                            height: 1.5,
                            color: PdfColor.fromHex('#D4AF37'), // Gold accent line
                          ),
                          pw.SizedBox(height: h * 0.025),

                          // Description
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(horizontal: w * 0.14),
                            child: pw.Text(
                              'In recognition of outstanding dedication, active participation, and successfully clearing the MCA Skill & Technical Aptitude Assessment Series.',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: interRegular,
                                fontSize: w * 0.0135,
                                color: PdfColor.fromHex('#334155'),
                                lineSpacing: 4,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: h * 0.03),

                          // Achievement Badges
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              _buildAchievementPillar('CRITICAL THINKING', w, interBold),
                              _buildDotDivider(w),
                              _buildAchievementPillar('TECHNICAL LOGIC', w, interBold),
                              _buildDotDivider(w),
                              _buildAchievementPillar('PROBLEM SOLVING', w, interBold),
                              _buildDotDivider(w),
                              _buildAchievementPillar('CAREER READINESS', w, interBold),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Signatures Section (Bottom left, center, right - above footer)
                    pw.Positioned(
                      bottom: 38,
                      left: w * 0.08,
                      right: w * 0.08,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Left Transparent PNG Signature
                          _buildSignatureBlock(
                            image: abhijeetSig,
                            name: 'Abhijeet Sonavane',
                            role: 'Co-Organizer',
                            w: w,
                            boldFont: interBold,
                            regFont: interRegular,
                          ),

                          // Center Official Stamp
                          pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 1.5),
                                ),
                                child: pw.Column(
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: [
                                    pw.Text(
                                      'OFFICIAL SEAL',
                                      style: pw.TextStyle(
                                        font: interBold,
                                        fontSize: w * 0.009,
                                        color: PdfColor.fromHex('#0F172A'),
                                      ),
                                    ),
                                    pw.SizedBox(height: 2),
                                    pw.Row(
                                      mainAxisSize: pw.MainAxisSize.min,
                                      children: [
                                        pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 8, color: PdfColor.fromHex('#D4AF37'))),
                                        pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 10, color: PdfColor.fromHex('#D4AF37'))),
                                        pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 8, color: PdfColor.fromHex('#D4AF37'))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Right Transparent PNG Signature
                          _buildSignatureBlock(
                            image: armanSig,
                            name: 'Arman Mulla',
                            role: 'Technical Coordinator',
                            w: w,
                            boldFont: interBold,
                            regFont: interRegular,
                          ),
                        ],
                      ),
                    ),

                    // Footer Strip
                    pw.Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: pw.Container(
                        height: 30,
                        color: PdfColor.fromHex('#0F172A'),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 10, color: PdfColor.fromHex('#D4AF37'))),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              'DEPARTMENT OF MCA • EXCELLENCE & KNOWLEDGE',
                              style: pw.TextStyle(
                                font: interBold,
                                fontSize: w * 0.011,
                                color: PdfColors.white,
                                letterSpacing: 3,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text('★', style: pw.TextStyle(font: interBold, fontSize: 10, color: PdfColor.fromHex('#D4AF37'))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCornerDeco(bool isTop, bool isLeft) {
    return pw.Container(
      width: 44,
      height: 44,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: isTop ? pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 3.5) : pw.BorderSide.none,
          bottom: !isTop ? pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 3.5) : pw.BorderSide.none,
          left: isLeft ? pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 3.5) : pw.BorderSide.none,
          right: !isLeft ? pw.BorderSide(color: PdfColor.fromHex('#D4AF37'), width: 3.5) : pw.BorderSide.none,
        ),
      ),
    );
  }

  static pw.Widget _buildAchievementPillar(String text, double w, pw.Font font) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('•', style: pw.TextStyle(font: font, fontSize: w * 0.014, color: PdfColor.fromHex('#1D4ED8'))),
        pw.SizedBox(width: 5),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: w * 0.0105,
            color: PdfColor.fromHex('#0F172A'),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDotDivider(double w) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: w * 0.014),
      child: pw.Container(
        width: 4,
        height: 4,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#D4AF37'),
          shape: pw.BoxShape.circle,
        ),
      ),
    );
  }

  static pw.Widget _buildSignatureBlock({
    required pw.MemoryImage? image,
    required String name,
    required String role,
    required double w,
    required pw.Font boldFont,
    required pw.Font regFont,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (image != null)
          pw.Image(image, width: w * 0.16, height: w * 0.055, fit: pw.BoxFit.contain)
        else
          pw.SizedBox(height: w * 0.055),
        pw.Container(
          width: w * 0.18,
          height: 1,
          color: PdfColor.fromHex('#0F172A'),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          name,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: w * 0.012,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.Text(
          role,
          style: pw.TextStyle(
            font: regFont,
            fontSize: w * 0.01,
            color: PdfColor.fromHex('#475569'),
          ),
        ),
      ],
    );
  }

  static String _formatTitleCase(String rawName) {
    if (rawName.trim().isEmpty) return 'Student';
    final words = rawName.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Print or Save PDF directly using Printing package
  static Future<void> printOrShareCertificate(Student student) async {
    final pdfBytes = await generateCertificatePdf(student);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Appreciation_Certificate_${student.grnNumber}.pdf',
    );
  }
}
