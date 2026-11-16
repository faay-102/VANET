import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vanet_mobile/core/theme/theme.dart';
import 'package:vanet_mobile/features/shared/authentication/presentation/auth_provider.dart';
import 'package:vanet_mobile/features/driver/presentation/driver_provider.dart';

import 'package:vanet_mobile/core/utils/responsive.dart';

class DriverNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final String? currentPath;

  const DriverNavigationShell({
    super.key,
    required this.navigationShell,
    this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    final appBar = AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'DRIVER OBU',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _getTitle(navigationShell.currentIndex),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        // Trust Badge on App Bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.safe.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.safe.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.safe),
              const SizedBox(width: 4),
              Text(
                '${(driverState.trustScore * 100).toInt()}% Trust',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.safe,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.alt_route_rounded, color: AppTheme.textPrimary),
          tooltip: 'Safe Route Detours',
          onPressed: () => context.push('/driver/safe-route'),
        ),
      ],
    );

    if (isWide) {
      final currentLoc = currentPath ?? '';

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

                    // Clean List of App Navigation Items (No Numbers, Clean App Naming)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.grid_view_rounded,
                            title: 'Dashboard',
                            isActive: currentLoc == '/dashboard',
                            onTap: () {
                              ref.read(authProvider.notifier).login('admin@vanet.com', 'admin123', role: 'Admin');
                              context.go('/dashboard');
                            },
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.shield_outlined,
                            title: 'AI Detection',
                            isActive: currentLoc == '/vehicles',
                            onTap: () => context.push('/vehicles'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.psychology_outlined,
                            title: 'Explainable AI',
                            isActive: currentLoc.contains('explanation'),
                            onTap: () => context.push('/vehicles/V1023/explanation'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.verified_user_outlined,
                            title: 'Trust Management',
                            isActive: currentLoc == '/trust',
                            onTap: () => context.push('/trust'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.alt_route_rounded,
                            title: 'Emergency Routes',
                            isActive: currentLoc.contains('/emergency'),
                            onTap: () => context.push('/emergency/route'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.directions_car_outlined,
                            title: 'Highway Simulator',
                            isActive: currentLoc == '/simulation' || currentLoc == '/driver/map',
                            onTap: () => context.go('/simulation'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.pie_chart_outline_rounded,
                            title: 'Security Reports',
                            isActive: currentLoc == '/reports',
                            onTap: () => context.push('/reports'),
                          ),
                          const SizedBox(height: 4),
                          _buildDriverSidebarTile(
                            context: context,
                            icon: Icons.notifications_none_rounded,
                            title: 'Alerts',
                            isActive: currentLoc == '/alerts',
                            onTap: () => context.push('/alerts'),
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: appBar,
      drawer: _buildDriverDrawer(context, ref, driverState),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              label: 'HUD Cockpit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_rounded),
              label: 'Nearby V2V',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Live Map',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Personal Safety HUD';
      case 1:
        return 'Surrounding V2V Radar';
      case 2:
        return 'Safety Alerts & Hazard';
      case 3:
        return 'VANET Navigation Map';
      default:
        return 'Driver Assistant';
    }
  }

  Widget _buildDriverDrawer(BuildContext context, WidgetRef ref, DriverState state) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary,
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.vehicleId,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          state.licensePlate,
                          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.safe,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OBU ONLINE',
                            style: GoogleFonts.outfit(
                              color: AppTheme.surface,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context: context,
                    icon: Icons.directions_car_outlined,
                    title: 'My Vehicle & OBU Info',
                    subtitle: 'Diagnostics, trust rating & registration',
                    route: '/driver/my-vehicle',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.emergency_rounded,
                    title: 'Emergency Priority & Siren',
                    subtitle: 'Corridor clearance & beacon status',
                    route: '/driver/emergency',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.alt_route_rounded,
                    title: 'Safe Route & Detour (A*)',
                    subtitle: 'AI-recommended safe corridors',
                    route: '/driver/safe-route',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.psychology_rounded,
                    title: 'AI Safety Explanation (XAI)',
                    subtitle: 'Plain-English anomaly breakdowns',
                    route: '/driver/xai/V1023',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.car_crash_outlined,
                    title: 'Accident & Hazard Alerts',
                    subtitle: 'Braking & hazard broadcast feed',
                    route: '/driver/hazards',
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.history_rounded,
                    title: 'Safety & Trip History',
                    subtitle: 'Timeline of alerts & routes taken',
                    route: '/driver/history',
                  ),
                  const Divider(height: 24),
                  // Switch to Admin mode for testing / demo convenience
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary),
                    title: Text(
                      'Switch to Admin Mode',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.primary),
                    ),
                    subtitle: Text('Demo switch to Central Security App', style: GoogleFonts.outfit(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).login('admin@vanet.com', 'admin123', role: 'Admin');
                      context.go('/dashboard');
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
                title: Text(
                  'Logout',
                  style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }

  Widget _buildDriverSidebarTile({
    required BuildContext context,
    required IconData icon,
    required String title,
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
