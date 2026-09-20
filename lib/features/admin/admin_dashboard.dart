import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_students_tab.dart';
import 'tabs/admin_assessments_tab.dart';
import 'tabs/admin_live_track_tab.dart';
import 'tabs/admin_security_tab.dart';
import 'tabs/admin_results_tab.dart';
import 'tabs/admin_final_list_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const AdminOverviewTab(),
    const AdminStudentsTab(),
    const AdminAssessmentsTab(),
    const AdminLiveTrackTab(),
    const AdminSecurityTab(),
    const AdminResultsTab(),
    const AdminFinalListTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MCA Admin Dashboard',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.headerNavy),
                ),
                Text(
                  AppConstants.departmentName,
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                authService.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out of Admin Portal')),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout Admin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.dangerRed,
                side: const BorderSide(color: AppTheme.dangerRed),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation Rail for Desktop / Tablet
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: MediaQuery.of(context).size.width > 900,
            minExtendedWidth: 220,
            backgroundColor: AppTheme.cardWhite,
            indicatorColor: AppTheme.surfaceBlue,
            selectedIconTheme: const IconThemeData(color: AppTheme.accentBlue),
            selectedLabelTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
            unselectedIconTheme: const IconThemeData(color: AppTheme.textMuted),
            unselectedLabelTextStyle: GoogleFonts.inter(color: AppTheme.textMuted),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_alt_rounded),
                label: Text('Student Records'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: Text('Assessments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sensors_rounded),
                selectedIcon: Icon(Icons.radar_rounded),
                label: Text('Live Track'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield_rounded),
                label: Text('Security & Audit'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.poll_outlined),
                selectedIcon: Icon(Icons.poll_rounded),
                label: Text('Results & Scores'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.workspace_premium_outlined),
                selectedIcon: Icon(Icons.workspace_premium_rounded),
                label: Text('Final List & Certificates'),
              ),
            ],
          ),


          const VerticalDivider(thickness: 1, width: 1, color: AppTheme.borderColor),

          // Main View Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabs[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
