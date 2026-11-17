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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 64,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE45D3F), // Signature Safety Orange
                  );
                }
                return GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex.clamp(0, 4),
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFE45D3F).withOpacity(0.14),
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
                // 1. Dashboard Tab
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined, color: Color(0xFF64748B), size: 22),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFFE45D3F), size: 22),
                  label: 'Dashboard',
                ),
                // 2. Vehicles & Misbehavior AI Detection Tab
                NavigationDestination(
                  icon: Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 22),
                  selectedIcon: Icon(Icons.shield_rounded, color: Color(0xFFE45D3F), size: 22),
                  label: 'Detection',
                ),
                // 3. Live Highway V2X Simulator Tab
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined, color: Color(0xFF64748B), size: 22),
                  selectedIcon: Icon(Icons.directions_car_rounded, color: Color(0xFFE45D3F), size: 22),
                  label: 'Simulator',
                ),
                // 4. Emergency Priority & Detours Tab
                NavigationDestination(
                  icon: Icon(Icons.alt_route_rounded, color: Color(0xFF64748B), size: 22),
                  selectedIcon: Icon(Icons.alt_route_rounded, color: Color(0xFFE45D3F), size: 22),
                  label: 'Emergency',
                ),
                // 5. Real-Time Alerts Tab
                NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
                  selectedIcon: Icon(Icons.notifications_active_rounded, color: Color(0xFFE45D3F), size: 22),
                  label: 'Alerts',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
