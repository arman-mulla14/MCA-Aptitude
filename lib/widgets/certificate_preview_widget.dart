import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/student.dart';

class CertificatePreviewWidget extends StatefulWidget {
  final Student student;

  const CertificatePreviewWidget({super.key, required this.student});

  @override
  State<CertificatePreviewWidget> createState() => _CertificatePreviewWidgetState();
}

class _CertificatePreviewWidgetState extends State<CertificatePreviewWidget> {
  Uint8List? _abhijeetBytes;
  Uint8List? _armanBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final results = await Future.wait([
        rootBundle.load('assets/signatures/abhijeet_signature.png'),
        rootBundle.load('assets/signatures/arman_signature.png'),
      ]);
      _abhijeetBytes = results[0].buffer.asUint8List();
      _armanBytes = results[1].buffer.asUint8List();
    } catch (_) {
      try {
        final resultsJpg = await Future.wait([
          rootBundle.load('assets/signatures/abhijeet_signature.jpg'),
          rootBundle.load('assets/signatures/arman_signature.jpg'),
        ]);
        _abhijeetBytes = resultsJpg[0].buffer.asUint8List();
        _armanBytes = resultsJpg[1].buffer.asUint8List();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTitleCase(String rawName) {
    if (rawName.trim().isEmpty) return 'Student';
    final words = rawName.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final rawName = widget.student.name.isNotEmpty ? widget.student.name : 'Student (${widget.student.grnNumber})';
    final formattedName = _formatTitleCase(rawName);

    return AspectRatio(
      aspectRatio: 1.414, // A4 Landscape ratio
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  return Container(
                    padding: const EdgeInsets.all(12), // Outer margin
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF0F172A), width: 3), // Outer deep navy border
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4), // Space between double borders
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5), // Inner metallic gold border
                        ),
                        child: Stack(
                          children: [
                            // Watermark / Background Texture
                            Center(
                              child: Opacity(
                                opacity: 0.03,
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  size: w * 0.45,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ),

                            // Corner Deco Top Left
                            Positioned(top: 0, left: 0, child: _buildCornerDeco(true, true)),
                            // Corner Deco Top Right
                            Positioned(top: 0, right: 0, child: _buildCornerDeco(true, false)),
                            // Corner Deco Bottom Left
                            Positioned(bottom: 30, left: 0, child: _buildCornerDeco(false, true)),
                            // Corner Deco Bottom Right
                            Positioned(bottom: 30, right: 0, child: _buildCornerDeco(false, false)),

                            // Main Content Column
                            Positioned.fill(
                              bottom: 30, // Space for footer
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Medal / Seal Icon Badge
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0F172A),
                                      border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Gold ring
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 34),
                                  ),
                                  SizedBox(height: h * 0.02),

                                  // Subheading
                                  Text(
                                    'DEPARTMENT OF MASTER OF COMPUTER APPLICATIONS',
                                    style: GoogleFonts.inter(
                                      fontSize: w * 0.012,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF475569),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: h * 0.008),

                                  // Title
                                  Text(
                                    'CERTIFICATE OF APPRECIATION',
                                    style: GoogleFonts.merriweather(
                                      fontSize: w * 0.038,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  SizedBox(height: h * 0.008),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: w * 0.12, height: 1.5, color: const Color(0xFFD4AF37)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFD4AF37)),
                                      const SizedBox(width: 12),
                                      Container(width: w * 0.12, height: 1.5, color: const Color(0xFFD4AF37)),
                                    ],
                                  ),
                                  SizedBox(height: h * 0.035),

                                  // Subtitle
                                  Text(
                                    'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                                    style: GoogleFonts.inter(
                                      fontSize: w * 0.012,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1D4ED8), // Royal Blue
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                  SizedBox(height: h * 0.015),

                                  // Dynamic Student Name (Fitted to single line Title Case)
                                  SizedBox(
                                    width: w * 0.65,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        formattedName,
                                        maxLines: 1,
                                        style: GoogleFonts.greatVibes(
                                          fontSize: w * 0.056,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: w * 0.38,
                                    height: 1.5,
                                    color: const Color(0xFFD4AF37), // Gold rule
                                  ),
                                  SizedBox(height: h * 0.025),

                                  // Description
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: w * 0.14),
                                    child: Text(
                                      'In recognition of outstanding dedication, active participation, and successfully clearing the MCA Skill & Technical Aptitude Assessment Series.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: w * 0.0135,
                                        color: const Color(0xFF334155),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: h * 0.03),

                                  // Achievement Pillars Badges
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildAchievementPillar(Icons.psychology_rounded, 'CRITICAL THINKING', w),
                                      _buildDotDivider(w),
                                      _buildAchievementPillar(Icons.code_rounded, 'TECHNICAL LOGIC', w),
                                      _buildDotDivider(w),
                                      _buildAchievementPillar(Icons.auto_awesome_rounded, 'PROBLEM SOLVING', w),
                                      _buildDotDivider(w),
                                      _buildAchievementPillar(Icons.emoji_events_rounded, 'CAREER READINESS', w),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Signatures Section (Bottom left, center, right - above footer)
                            Positioned(
                              bottom: 38,
                              left: w * 0.08,
                              right: w * 0.08,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Left Transparent PNG Signature
                                  _buildSignatureBlock(
                                    imageBytes: _abhijeetBytes,
                                    name: 'Abhijeet Sonavane',
                                    role: 'Co-Organizer',
                                    w: w,
                                  ),

                                  // Center Official Seal
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'OFFICIAL SEAL',
                                              style: GoogleFonts.inter(
                                                fontSize: w * 0.009,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F172A),
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.star_rounded, size: 9, color: Color(0xFFD4AF37)),
                                                Icon(Icons.star_rounded, size: 11, color: Color(0xFFD4AF37)),
                                                Icon(Icons.star_rounded, size: 9, color: Color(0xFFD4AF37)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right Transparent PNG Signature
                                  _buildSignatureBlock(
                                    imageBytes: _armanBytes,
                                    name: 'Arman Mulla',
                                    role: 'Technical Coordinator',
                                    w: w,
                                  ),
                                ],
                              ),
                            ),

                            // Footer Strip
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 30,
                                color: const Color(0xFF0F172A),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'DEPARTMENT OF MCA • EXCELLENCE & KNOWLEDGE',
                                      style: GoogleFonts.inter(
                                        fontSize: w * 0.011,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD4AF37)),
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
      ),
    );
  }

  Widget _buildCornerDeco(bool isTop, bool isLeft) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFFD4AF37), width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFFD4AF37), width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFFD4AF37), width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFFD4AF37), width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAchievementPillar(IconData icon, String text, double w) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: w * 0.014, color: const Color(0xFF1D4ED8)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: w * 0.0105,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDotDivider(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.014),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFFD4AF37),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSignatureBlock({
    required Uint8List? imageBytes,
    required String name,
    required String role,
    required double w,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageBytes != null)
          Image.memory(
            imageBytes,
            width: w * 0.16,
            height: w * 0.055,
            fit: BoxFit.contain,
            // Transparent PNG rendering
          )
        else
          SizedBox(height: w * 0.055),
        Container(
          width: w * 0.18,
          height: 1,
          color: const Color(0xFF0F172A),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: w * 0.012,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          role,
          style: GoogleFonts.inter(
            fontSize: w * 0.01,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
