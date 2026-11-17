import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vanet_mobile/core/theme/colors.dart';
import 'package:vanet_mobile/features/admin/dashboard/presentation/widgets/section_header.dart';
import 'package:vanet_mobile/models/vehicle_model.dart';

class LiveNetworkPreview extends StatelessWidget {
  final List<VehicleModel> vehicles;

  const LiveNetworkPreview({
    super.key,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Live Network & Fleet Simulation',
        ),
        const SizedBox(height: 10),

        // Modern 3D Road Preview Card (Light Theme)
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
                  children: [
                    // Vector Highway Grid Paint
                    CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _CyberRoadGridPainter(),
                    ),

                    // 3D Stylized Vehicle Nodes on Map
                    _build3DCarNode(
                      top: 48,
                      left: 60,
                      color: const Color(0xFF7C3AED),
                      accentColor: const Color(0xFF6366F1),
                      label: 'Host',
                      icon: Icons.directions_car_rounded,
                      status: 'TRUSTED 94%',
                      statusColor: AppColors.safe,
                    ),
                    _build3DCarNode(
                      top: 36,
                      left: 195,
                      color: const Color(0xFFD97706),
                      accentColor: const Color(0xFFFBBF24),
                      label: 'V-203 (Civ)',
                      icon: Icons.directions_car_rounded,
                      status: 'NORMAL 88%',
                      statusColor: const Color(0xFFFBBF24),
                    ),
                    _build3DCarNode(
                      top: 108,
                      left: 130,
                      color: const Color(0xFF991B1B),
                      accentColor: const Color(0xFFEF4444),
                      label: 'V-305 (Rogue)',
                      icon: Icons.warning_rounded,
                      status: 'SYBIL ATTACK',
                      statusColor: AppColors.error,
                      isMalicious: true,
                    ),
                    _build3DCarNode(
                      top: 96,
                      left: 260,
                      color: const Color(0xFF1D4ED8),
                      accentColor: const Color(0xFF60A5FA),
                      label: 'AMB-404',
                      icon: Icons.local_hospital_rounded,
                      status: 'PRIORITY GRANTED',
                      statusColor: const Color(0xFF38BDF8),
                      isEmergency: true,
                    ),

                    // Floating Tooltip Badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full_rounded,
                                size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 5),
                            Text(
                              'Tap to launch Full 3D Simulator',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

        const SizedBox(height: 10),

        // Status Legend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendDot('Trusted', AppColors.safe),
            _buildLegendDot('Suspicious', AppColors.warning),
            _buildLegendDot('Malicious Flagged', AppColors.error),
            _buildLegendDot('Emergency Corridor', const Color(0xFF2563EB)),
          ],
        ),
      ],
    );
  }

  Widget _build3DCarNode({
    required double top,
    required double left,
    required Color color,
    required Color accentColor,
    required String label,
    required IconData icon,
    required String status,
    required Color statusColor,
    bool isEmergency = false,
    bool isMalicious = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D-Styled Car Avatar Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isMalicious ? Colors.redAccent : Colors.white60,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isMalicious ? Colors.red : color).withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CyberRoadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Background
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. High-Tech Multi-lane Roads (Clean Light Theme)
    final roadBasePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activeRoutePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.85) // Emergency Green Corridor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashedCenterPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(20, 60)
      ..lineTo(size.width * 0.45, 60)
      ..lineTo(size.width * 0.68, 130)
      ..lineTo(size.width - 20, 130);

    final path2 = Path()
      ..moveTo(size.width * 0.45, 60)
      ..lineTo(size.width * 0.45, size.height - 20)
      ..lineTo(size.width * 0.85, size.height - 20);

    // Draw borders & asphalt
    canvas.drawPath(path1, roadBorderPaint);
    canvas.drawPath(path1, roadBasePaint);
    canvas.drawPath(path1, dashedCenterPaint);

    canvas.drawPath(path2, roadBorderPaint);
    canvas.drawPath(path2, roadBasePaint);
    canvas.drawPath(path2, dashedCenterPaint);

    // Active Detour Priority Route
    final activePath = Path()
      ..moveTo(60, 60)
      ..lineTo(size.width * 0.45, 60)
      ..lineTo(size.width * 0.68, 130)
      ..lineTo(size.width * 0.78, 130);

    canvas.drawPath(activePath, activeRoutePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
