import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanet_mobile/core/theme/theme.dart';
import 'package:vanet_mobile/core/utils/responsive.dart';

class NavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String? currentPath;

  const NavigationShell({
    super.key,
    required this.navigationShell,
    this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final currentLoc = currentPath ?? '';

    if (isWide) {
      // 🔹 Clean Desktop Sidebar with Exact FYP Project Module Points
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // Left Clean Module Sidebar
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VANET Guard',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Network Security',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Sidebar Section Title
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 16, bottom: 8),
                      child: Text(
                        'MENU',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    // Clean List of App Navigation Items (All 8 Persistent Shell Tabs)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.grid_view_rounded,
                            title: 'Dashboard',
                            path: '/dashboard',
                            isActive: currentLoc == '/dashboard' || navigationShell.currentIndex == 0,
                            onTap: () => context.go('/dashboard'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.shield_outlined,
                            title: 'AI Detection',
                            path: '/vehicles',
                            isActive: currentLoc == '/vehicles' || navigationShell.currentIndex == 1,
                            onTap: () => context.go('/vehicles'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.psychology_outlined,
                            title: 'Explainable AI',
                            path: '/xai',
                            isActive: currentLoc == '/xai' || currentLoc.contains('explanation') || navigationShell.currentIndex == 2,
                            onTap: () => context.go('/xai'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.verified_user_outlined,
                            title: 'Trust Management',
                            path: '/trust',
                            isActive: currentLoc == '/trust' || navigationShell.currentIndex == 3,
                            onTap: () => context.go('/trust'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.alt_route_rounded,
                            title: 'Emergency Routes',
                            path: '/emergency',
                            isActive: currentLoc.contains('/emergency') || navigationShell.currentIndex == 4,
                            onTap: () => context.go('/emergency'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.directions_car_outlined,
                            title: 'Highway Simulator',
                            path: '/simulation',
                            isActive: currentLoc == '/simulation' || currentLoc == '/driver/map' || navigationShell.currentIndex == 5,
                            onTap: () => context.go('/simulation'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.pie_chart_outline_rounded,
                            title: 'Security Reports',
                            path: '/reports',
                            isActive: currentLoc == '/reports' || navigationShell.currentIndex == 6,
                            onTap: () => context.go('/reports'),
                          ),
                          const SizedBox(height: 4),
                          _buildSidebarTile(
                            context: context,
                            icon: Icons.notifications_none_rounded,
                            title: 'Alerts',
                            path: '/alerts',
                            isActive: currentLoc == '/alerts' || navigationShell.currentIndex == 7,
                            onTap: () => context.go('/alerts'),
                          ),
                        ],
                      ),
                    ),

                    // Clean Footer Info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Text(
                              'OBU System Active',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
      );
    }

    // 🔹 Responsive Mobile Layout with Clean Bottom Navigation Bar
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7));
              }
              return GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B));
            }),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex < 5 ? navigationShell.currentIndex : 0,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Color(0xFF64748B), size: 22),
                selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0284C7), size: 22),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_car_outlined, color: Color(0xFF64748B), size: 22),
                selectedIcon: Icon(Icons.directions_car_rounded, color: Color(0xFF0284C7), size: 22),
                label: 'Detection',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
                selectedIcon: Icon(Icons.notifications_active_rounded, color: Color(0xFF0284C7), size: 22),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_hospital_outlined, color: Color(0xFF64748B), size: 22),
                selectedIcon: Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 22),
                label: 'Emergency',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_outlined, color: Color(0xFF64748B), size: 22),
                selectedIcon: Icon(Icons.article_rounded, color: Color(0xFF0284C7), size: 22),
                label: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String path,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF0284C7).withValues(alpha: 0.25) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
