import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanet_mobile/features/driver/presentation/driver_provider.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    // 15-second complete automated cycle looping continuously
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animController.stop();
      } else {
        _animController.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🛣️ Interactive VANET Simulation Canvas
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final cycle = _animController.value;
              final autoState = _getAutonomousState(cycle);

              return SizedBox.expand(
                child: CustomPaint(
                  painter: _VanetSimulationPainter(
                    cycle: cycle,
                    autoState: autoState,
                    baseTrust: driverState.trustScore,
                  ),
                ),
              );
            },
          ),

          // 🛰️ TOP STEP-BY-STEP PROGRESS & EXPLANATION BANNER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final cycle = _animController.value;
                  final autoState = _getAutonomousState(cycle);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Live Step Header Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (Navigator.canPop(context)) ...[
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
                                tooltip: 'Back',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: autoState.stepColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(autoState.stepIcon, color: autoState.stepColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: autoState.stepColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          autoState.stepTag,
                                          style: GoogleFonts.outfit(
                                            color: autoState.stepColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'V2X SMART HIGHWAY',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.5,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    autoState.headline,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    autoState.subtext,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Pause / Resume Button
                            IconButton(
                              icon: Icon(
                                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: const Color(0xFF0284C7),
                                size: 24,
                              ),
                              tooltip: _isPaused ? 'Resume Simulation' : 'Pause Simulation',
                              onPressed: _togglePlayPause,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 2. 5-Step Pipeline Indicators
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _stepPill('1. V2X Cruise', autoState.stepIndex == 1),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                            _stepPill('2. Obstacle Alert', autoState.stepIndex == 2),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                            _stepPill('3. Siren Preempt', autoState.stepIndex == 3),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                            _stepPill('4. Detour Yield', autoState.stepIndex == 4),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                            _stepPill('5. Trust Rewarded', autoState.stepIndex == 5),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 📊 BOTTOM REAL-TIME VANET METRICS HUD
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final cycle = _animController.value;
                final autoState = _getAutonomousState(cycle);
                final trustDisplay = ((driverState.trustScore + autoState.trustBonus).clamp(0.0, 1.0) * 100).toInt();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statTile('RSU TOWER', autoState.rsuStatus, autoState.rsuColor, Icons.cell_tower_rounded),
                      Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                      _statTile('V2V BEACON', autoState.v2vPacketStatus, const Color(0xFF0284C7), Icons.wifi_tethering_rounded),
                      Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                      _statTile('ROAD HAZARD', autoState.hazardStatus, autoState.hazardColor, Icons.warning_amber_rounded),
                      Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                      _statTile('AMBULANCE', autoState.ambulanceStatus, autoState.ambulanceColor, Icons.local_hospital_rounded),
                      Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                      _statTile('DYNAMIC TRUST', '$trustDisplay% Trust', const Color(0xFF10B981), Icons.verified_user_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPill(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 12.0, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 🧠 Autonomous VANET State Machine (15-second continuous cycle)
  _AutoState _getAutonomousState(double cycle) {
    if (cycle < 0.20) {
      // 0.0 - 0.20 (0s - 3s): Phase 1: Normal Cruise & V2V CAM Exchange
      return _AutoState(
        stepIndex: 1,
        stepTag: 'STEP 1: V2X COOPERATIVE CRUISE',
        headline: 'Cooperative Cruising with Regular Traffic',
        subtext: 'Vehicles (V-101, V-204) exchange 10Hz CAM beacons. RSU-04 transmits signal timing.',
        stepIcon: Icons.wifi_rounded,
        stepColor: const Color(0xFF059669),
        playerLaneTarget: 0.0, // Center Lane
        carAheadLaneTarget: 0.0, // Center Lane ahead
        isObstacleVisible: false,
        isDetourActive: false,
        isAmbulanceVisible: false,
        ambulanceYProgress: 1.5,
        isBlinkerActive: false,
        isSignalBlinkingRed: false,
        isCorridorActive: false,
        rsuStatus: 'Online (5.9 GHz)',
        rsuColor: const Color(0xFF059669),
        v2vPacketStatus: '10 Hz CAM (Normal)',
        hazardStatus: 'Lane 1 Clear',
        hazardColor: const Color(0xFF059669),
        ambulanceStatus: 'None in Range',
        ambulanceColor: const Color(0xFF64748B),
        signalStatus: '🟢 Green (Clear)',
        signalColor: const Color(0xFF059669),
        trustBonus: 0.0,
      );
    } else if (cycle < 0.40) {
      // 0.20 - 0.40 (3s - 6s): Phase 2: Accident Obstacle Detected Ahead in Lane 1!
      return _AutoState(
        stepIndex: 2,
        stepTag: 'STEP 2: ROAD HAZARD DETECTED',
        headline: '⚠️ Lane 1 Blocked by Crash! RSU Emits DENM Hazard Alert',
        subtext: 'Crash detected at km 4.2. RSU broadcasts emergency detour. Turn right arrows activate!',
        stepIcon: Icons.warning_rounded,
        stepColor: const Color(0xFFF59E0B),
        playerLaneTarget: 0.2, // Begins drifting right
        carAheadLaneTarget: 0.8, // Car ahead reacts first and begins shifting
        isObstacleVisible: true,
        isDetourActive: true,
        isAmbulanceVisible: false,
        ambulanceYProgress: 1.5,
        isBlinkerActive: true,
        isSignalBlinkingRed: false,
        isCorridorActive: false,
        rsuStatus: 'DENM Broadcast',
        rsuColor: const Color(0xFFF59E0B),
        v2vPacketStatus: 'DENM Hazard Alert',
        hazardStatus: 'Lane 1 Blocked (Crash)',
        hazardColor: const Color(0xFFDC2626),
        ambulanceStatus: 'Dispatched (400m)',
        ambulanceColor: const Color(0xFFF59E0B),
        signalStatus: '🟡 Advisory Slow',
        signalColor: const Color(0xFFF59E0B),
        trustBonus: 0.0,
      );
    } else if (cycle < 0.65) {
      // 0.40 - 0.65 (6s - 9.7s): Phase 3: Ambulance Approaching Fast with Siren & Preemption
      final approach = (cycle - 0.40) / 0.25;
      final distMeters = (60.0 - (approach * 35.0)).toInt();

      return _AutoState(
        stepIndex: 3,
        stepTag: 'STEP 3: EMERGENCY SIREN DETECTED',
        headline: '🚨 Emergency Ambulance Behind You (${distMeters}m)! V2V Siren Alert',
        subtext: 'AMB-1122 requests priority corridor. Overhead signal gantry blinks red for holding.',
        stepIcon: Icons.notifications_active_rounded,
        stepColor: const Color(0xFFDC2626),
        playerLaneTarget: 0.5 + (approach * 0.4), // Shifting to right yield lane
        carAheadLaneTarget: 1.0, // Car ahead has fully shifted right
        isObstacleVisible: true,
        isDetourActive: true,
        isAmbulanceVisible: true,
        ambulanceYProgress: 0.90 - (approach * 0.32),
        isBlinkerActive: true,
        isSignalBlinkingRed: true,
        isCorridorActive: true,
        rsuStatus: 'Preemption Mode',
        rsuColor: const Color(0xFFDC2626),
        v2vPacketStatus: 'Priority V2V Request',
        hazardStatus: 'Detour Active ➔',
        hazardColor: const Color(0xFFDC2626),
        ambulanceStatus: 'Behind You (${distMeters}m)',
        ambulanceColor: const Color(0xFFDC2626),
        signalStatus: '🔴 Blinking Red (Hold)',
        signalColor: const Color(0xFFDC2626),
        trustBonus: 0.01,
      );
    } else if (cycle < 0.85) {
      // 0.65 - 0.85 (9.7s - 12.7s): Phase 4: Ambulance Sweeps Through Cleared Corridor at 95 km/h
      final passProgress = (cycle - 0.65) / 0.20;
      final ambY = 0.58 - (passProgress * 0.95);

      return _AutoState(
        stepIndex: 4,
        stepTag: 'STEP 4: COOPERATIVE DETOUR & PASS',
        headline: '⚡ Vehicles Cleared into Detour Lane; Ambulance Speeds Past (95 km/h)',
        subtext: 'Cooperative driving verified via V2V. Express green corridor kept unobstructed.',
        stepIcon: Icons.bolt_rounded,
        stepColor: const Color(0xFF059669),
        playerLaneTarget: 1.0, // Fully yielded in right detour lane
        carAheadLaneTarget: 1.0,
        isObstacleVisible: true,
        isDetourActive: true,
        isAmbulanceVisible: true,
        ambulanceYProgress: ambY,
        isBlinkerActive: false,
        isSignalBlinkingRed: true,
        isCorridorActive: true,
        rsuStatus: 'Corridor Active',
        rsuColor: const Color(0xFF059669),
        v2vPacketStatus: 'V2V Yield Verified',
        hazardStatus: 'Bypassing Crash',
        hazardColor: const Color(0xFF059669),
        ambulanceStatus: 'Passing (95 km/h)',
        ambulanceColor: const Color(0xFF059669),
        signalStatus: '🟢 Green Wave Active',
        signalColor: const Color(0xFF059669),
        trustBonus: 0.02,
      );
    } else {
      // 0.85 - 1.0 (12.7s - 15s): Phase 5: Normal Navigation Resumes & Trust Reward
      final returnProgress = 1.0 - ((cycle - 0.85) / 0.15).clamp(0.0, 1.0);

      return _AutoState(
        stepIndex: 5,
        stepTag: 'STEP 5: TRUST REWARD & RESUME',
        headline: '🎉 Corridor Cleared! Dynamic Trust Score Rewarded (+2% Bonus)',
        subtext: 'Ambulance cleared the accident zone safely. Signals normalize, normal traffic resumes.',
        stepIcon: Icons.verified_user_rounded,
        stepColor: const Color(0xFF0284C7),
        playerLaneTarget: returnProgress, // Returning to center lane
        carAheadLaneTarget: returnProgress,
        isObstacleVisible: false,
        isDetourActive: false,
        isAmbulanceVisible: false,
        ambulanceYProgress: -0.5,
        isBlinkerActive: false,
        isSignalBlinkingRed: false,
        isCorridorActive: false,
        rsuStatus: 'Normal (100% OK)',
        rsuColor: const Color(0xFF059669),
        v2vPacketStatus: 'CAM Broadcast',
        hazardStatus: 'Incident Cleared',
        hazardColor: const Color(0xFF059669),
        ambulanceStatus: 'Passed Ahead',
        ambulanceColor: const Color(0xFF059669),
        signalStatus: '🟢 Green (Normal)',
        signalColor: const Color(0xFF059669),
        trustBonus: 0.02,
      );
    }
  }
}

class _AutoState {
  final int stepIndex;
  final String stepTag;
  final String headline;
  final String subtext;
  final IconData stepIcon;
  final Color stepColor;
  final double playerLaneTarget; // 0.0: Center, 1.0: Right
  final double carAheadLaneTarget;
  final bool isObstacleVisible;
  final bool isDetourActive;
  final bool isAmbulanceVisible;
  final double ambulanceYProgress;
  final bool isBlinkerActive;
  final bool isSignalBlinkingRed;
  final bool isCorridorActive;
  final String rsuStatus;
  final Color rsuColor;
  final String v2vPacketStatus;
  final String hazardStatus;
  final Color hazardColor;
  final String ambulanceStatus;
  final Color ambulanceColor;
  final String signalStatus;
  final Color signalColor;
  final double trustBonus;

  _AutoState({
    required this.stepIndex,
    required this.stepTag,
    required this.headline,
    required this.subtext,
    required this.stepIcon,
    required this.stepColor,
    required this.playerLaneTarget,
    required this.carAheadLaneTarget,
    required this.isObstacleVisible,
    required this.isDetourActive,
    required this.isAmbulanceVisible,
    required this.ambulanceYProgress,
    required this.isBlinkerActive,
    required this.isSignalBlinkingRed,
    required this.isCorridorActive,
    required this.rsuStatus,
    required this.rsuColor,
    required this.v2vPacketStatus,
    required this.hazardStatus,
    required this.hazardColor,
    required this.ambulanceStatus,
    required this.ambulanceColor,
    required this.signalStatus,
    required this.signalColor,
    required this.trustBonus,
  });
}

// 🎨 Comprehensive VANET Smart Highway Custom Painter
class _VanetSimulationPainter extends CustomPainter {
  final double cycle;
  final _AutoState autoState;
  final double baseTrust;

  _VanetSimulationPainter({
    required this.cycle,
    required this.autoState,
    required this.baseTrust,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.44; // Center of highway (shifted slightly left to leave room for RSU tower on right)

    // 1. Terrain Grass (Clean Light Green Lawn on both sides)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF0FDF4));

    // 2. 3-Lane Smart Highway (340px wide)
    // Lane 1 (Express / Incident): cx - 110
    // Lane 2 (Main Cruise): cx
    // Lane 3 (Detour / Yield): cx + 110
    const double roadWidth = 340.0;
    final roadRect = Rect.fromCenter(center: Offset(cx, size.height * 0.5), width: roadWidth, height: size.height);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF334155)); // Crisp asphalt dark slate

    // Highway Concrete Curbs & Shoulder markings
    final curbPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 4.0;
    canvas.drawLine(Offset(cx - roadWidth * 0.5, 0), Offset(cx - roadWidth * 0.5, size.height), curbPaint);
    canvas.drawLine(Offset(cx + roadWidth * 0.5, 0), Offset(cx + roadWidth * 0.5, size.height), curbPaint);

    // 3. Moving Lane Dashed Dividers (Between Lane 1-2 and Lane 2-3)
    _drawMovingDashedLine(canvas, cx - 55, size.height, cycle);
    _drawMovingDashedLine(canvas, cx + 55, size.height, cycle);

    // 4. Directional Forward Arrows on Pavement
    _drawDirectionalArrows(canvas, cx, size.height, cycle);

    // 5. Emergency Green Wave Corridor
    if (autoState.isCorridorActive) {
      final corridorPaint = Paint()..color = const Color(0xFF22C55E).withValues(alpha: 0.28);
      canvas.drawRect(Rect.fromLTWH(cx - roadWidth * 0.5, 0, 110, size.height), corridorPaint);
    }

    // 6. 🚧 Road Hazard Obstacle / Accident in Lane 1
    if (autoState.isObstacleVisible) {
      final obstacleY = size.height * 0.22;
      _drawAccidentObstacle(canvas, Offset(cx - 110, obstacleY), cycle);

      // Dynamic Animated Detour Arrows pointing to Lane 2 & Lane 3
      _drawDetourArrows(canvas, Offset(cx - 110, obstacleY + 70), cycle);
    }

    // 7. 🚦 Overhead Smart Traffic Signal Gantry
    _drawTrafficSignalGantry(canvas, cx, autoState.isSignalBlinkingRed, cycle);

    // 8. 📡 RSU Roadside Unit / 5G Transmission Tower
    final rsuPos = Offset(cx + roadWidth * 0.5 + 80, size.height * 0.38);
    _drawRSUTower(canvas, rsuPos, cycle, autoState.rsuColor);

    // 9. 🚗 VEHICLE POSITIONS:
    // A. Lead Civilian Sedan (V-204)
    final carAheadX = cx + (autoState.carAheadLaneTarget * 110.0);
    final carAheadY = size.height * 0.34;

    // B. Host Vehicle (YOU - V-101)
    final playerX = cx + (autoState.playerLaneTarget * 110.0);
    final playerY = size.height * 0.55;

    // C. Malicious Perimeter Vehicle (V-308)
    final malicX = cx + roadWidth * 0.5 + 40;
    final malicY = size.height * 0.72;

    // D. Ambulance (AMB-1122)
    final ambX = cx - 110;
    final ambY = size.height * autoState.ambulanceYProgress;

    // 10. ⚡ WIRELESS VANET V2V & V2I COMMUNICATION WAVES
    _drawVanetWirelessWaves(
      canvas: canvas,
      rsuPos: rsuPos,
      playerPos: Offset(playerX, playerY),
      carAheadPos: Offset(carAheadX, carAheadY),
      ambPos: autoState.isAmbulanceVisible ? Offset(ambX, ambY) : null,
      cycle: cycle,
      isEmergency: autoState.isAmbulanceVisible,
    );

    // 11. DRAW VEHICLES
    // Lead Civilian Sedan (V-204)
    _drawCar(
      canvas: canvas,
      pos: Offset(carAheadX, carAheadY),
      bodyColor: const Color(0xFF64748B),
      roofColor: const Color(0xFF94A3B8),
      label: 'CAR (V-204)',
      hasRightBlinker: autoState.isBlinkerActive && ((cycle * 24).floor() % 2 == 0),
    );

    // Host Vehicle (YOU - V-101)
    _drawCar(
      canvas: canvas,
      pos: Offset(playerX, playerY),
      bodyColor: const Color(0xFF0284C7),
      roofColor: const Color(0xFF38BDF8),
      label: 'YOU (V-101)',
      hasRightBlinker: autoState.isBlinkerActive && ((cycle * 24).floor() % 2 == 0),
    );

    // Malicious Perimeter Vehicle (V-308)
    _drawCar(
      canvas: canvas,
      pos: Offset(malicX, malicY),
      bodyColor: const Color(0xFFDC2626),
      roofColor: const Color(0xFFF87171),
      label: '⚠️ V-308 (Fake GPS)',
      hasRightBlinker: false,
      isFlaggedAnomaly: true,
    );

    // Ambulance (AMB-1122)
    if (autoState.isAmbulanceVisible) {
      _drawAmbulance(
        canvas: canvas,
        pos: Offset(ambX, ambY),
        label: '🚑 AMBULANCE 1122 (95 km/h)',
        cycle: cycle,
      );
    }
  }

  void _drawMovingDashedLine(Canvas canvas, double x, double height, double anim) {
    final dashPaint = Paint()..color = Colors.white..strokeWidth = 2.5;
    const double dashLen = 24.0;
    const double gap = 20.0;
    final double offset = (anim * 220.0) % (dashLen + gap);

    for (double y = -dashLen + offset; y < height; y += (dashLen + gap)) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashLen), dashPaint);
    }
  }

  void _drawDirectionalArrows(Canvas canvas, double cx, double height, double anim) {
    final arrowPaint = Paint()..color = Colors.white24..strokeWidth = 2.0;

    for (double y = 80; y < height; y += 220) {
      final effectiveY = (y + anim * 160.0) % height;
      _drawSingleArrow(canvas, Offset(cx - 110, effectiveY), arrowPaint);
      _drawSingleArrow(canvas, Offset(cx, effectiveY), arrowPaint);
      _drawSingleArrow(canvas, Offset(cx + 110, effectiveY), arrowPaint);
    }
  }

  void _drawSingleArrow(Canvas canvas, Offset pos, Paint paint) {
    final path = Path()
      ..moveTo(pos.dx, pos.dy - 12)
      ..lineTo(pos.dx - 6, pos.dy - 2)
      ..moveTo(pos.dx, pos.dy - 12)
      ..lineTo(pos.dx + 6, pos.dy - 2)
      ..moveTo(pos.dx, pos.dy - 12)
      ..lineTo(pos.dx, pos.dy + 12);
    canvas.drawPath(path, paint);
  }

  // 🚧 Accident Obstacle in Lane 1 with Hazard Stripes & Cones
  void _drawAccidentObstacle(Canvas canvas, Offset pos, double anim) {
    // 1. Crash Hazard Barrier
    const double bw = 80.0;
    const double bh = 26.0;
    final bRect = Rect.fromCenter(center: pos, width: bw, height: bh);

    // Hazard Stripes (Yellow & Black)
    canvas.drawRRect(RRect.fromRectAndRadius(bRect, const Radius.circular(6)), Paint()..color = const Color(0xFFF59E0B));
    final stripePaint = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 5.0;
    for (double i = -bw * 0.5 + 4; i < bw * 0.5; i += 14) {
      canvas.drawLine(Offset(pos.dx + i, pos.dy - bh * 0.5), Offset(pos.dx + i + 8, pos.dy + bh * 0.5), stripePaint);
    }

    // Flashing Strobe Beacon on Barrier
    final isStrobe = ((anim * 24).floor() % 2) == 0;
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - bh * 0.5 - 6),
      7.0,
      Paint()
        ..color = isStrobe ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Traffic Cones
    _drawCone(canvas, Offset(pos.dx - 32, pos.dy + 22));
    _drawCone(canvas, Offset(pos.dx + 32, pos.dy + 22));

    // 3. Floating Incident Alert Badge
    _drawBadge(canvas, pos.translate(0, -32), '⚠️ ACCIDENT IN LANE 1', const Color(0xFFDC2626));
  }

  void _drawCone(Canvas canvas, Offset pos) {
    final conePath = Path()
      ..moveTo(pos.dx, pos.dy - 12)
      ..lineTo(pos.dx - 8, pos.dy + 6)
      ..lineTo(pos.dx + 8, pos.dy + 6)
      ..close();
    canvas.drawPath(conePath, Paint()..color = const Color(0xFFEA580C));
    // White reflective band
    canvas.drawLine(Offset(pos.dx - 4, pos.dy), Offset(pos.dx + 4, pos.dy), Paint()..color = Colors.white..strokeWidth = 2.5);
  }

  // ➡️ Animated Detour Turn Arrows on Asphalt
  void _drawDetourArrows(Canvas canvas, Offset pos, double anim) {
    final detourPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pulse = math.sin(anim * math.pi * 8) * 4;

    // Curved arrow pointing from Lane 1 into Lane 2 & 3
    final path = Path()
      ..moveTo(pos.dx - 10, pos.dy)
      ..quadraticBezierTo(pos.dx + 25, pos.dy, pos.dx + 60 + pulse, pos.dy + 35);

    // Arrow Head
    final head = Path()
      ..moveTo(pos.dx + 60 + pulse, pos.dy + 35)
      ..lineTo(pos.dx + 46 + pulse, pos.dy + 30)
      ..moveTo(pos.dx + 60 + pulse, pos.dy + 35)
      ..lineTo(pos.dx + 52 + pulse, pos.dy + 22);

    canvas.drawPath(path, detourPaint);
    canvas.drawPath(head, detourPaint);

    // Detour Text Label
    final tp = TextPainter(
      text: TextSpan(
        text: 'DETOUR RIGHT ➔',
        style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - 10, pos.dy + 6));
  }

  // 📡 RSU Roadside Unit Mast & 5G Wireless Tower
  void _drawRSUTower(Canvas canvas, Offset pos, double anim, Color rsuColor) {
    // 1. Steel Tower Truss Legs
    final towerPaint = Paint()..color = const Color(0xFF64748B)..strokeWidth = 2.0;
    canvas.drawLine(Offset(pos.dx - 16, pos.dy + 45), Offset(pos.dx, pos.dy - 35), towerPaint);
    canvas.drawLine(Offset(pos.dx + 16, pos.dy + 45), Offset(pos.dx, pos.dy - 35), towerPaint);
    canvas.drawLine(Offset(pos.dx - 10, pos.dy + 15), Offset(pos.dx + 10, pos.dy + 15), towerPaint);
    canvas.drawLine(Offset(pos.dx - 6, pos.dy - 5), Offset(pos.dx + 6, pos.dy - 5), towerPaint);

    // Antenna Base Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 35), width: 18, height: 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF334155),
    );

    // Microwave Dish & Mast
    canvas.drawLine(Offset(pos.dx, pos.dy - 42), Offset(pos.dx, pos.dy - 55), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 3);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 55), 5.0, Paint()..color = rsuColor);

    // Pulsing Concentric Wireless Radio Wave Rings
    for (int i = 0; i < 3; i++) {
      final waveProgress = ((anim * 2.0) + (i * 0.33)) % 1.0;
      final waveRadius = 15.0 + (waveProgress * 75.0);
      final waveOpacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.55;

      canvas.drawCircle(
        Offset(pos.dx, pos.dy - 55),
        waveRadius,
        Paint()
          ..color = rsuColor.withValues(alpha: waveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // RSU Badge
    _drawBadge(canvas, Offset(pos.dx, pos.dy + 65), '📡 RSU-04 (5.9 GHz C-V2X)', const Color(0xFF0284C7));
  }

  // ⚡ Visualizing V2V (Vehicle-to-Vehicle) and V2I (Vehicle-to-Infrastructure) Beams
  void _drawVanetWirelessWaves({
    required Canvas canvas,
    required Offset rsuPos,
    required Offset playerPos,
    required Offset carAheadPos,
    required Offset? ambPos,
    required double cycle,
    required bool isEmergency,
  }) {
    // 1. V2I Link: RSU to Host Car
    _drawDataBeam(
      canvas: canvas,
      from: Offset(rsuPos.dx, rsuPos.dy - 55),
      to: playerPos,
      color: const Color(0xFF0284C7),
      cycle: cycle,
      label: 'V2I SPaT (4ms)',
    );

    // 2. V2V Link: Host Car (V-101) to Car Ahead (V-204)
    _drawDataBeam(
      canvas: canvas,
      from: playerPos,
      to: carAheadPos,
      color: const Color(0xFF10B981),
      cycle: cycle,
      label: 'V2V CAM (10 Hz)',
    );

    // 3. V2V Emergency Siren Link: Ambulance to Host Car
    if (ambPos != null) {
      _drawDataBeam(
        canvas: canvas,
        from: ambPos,
        to: playerPos,
        color: const Color(0xFFDC2626),
        cycle: cycle,
        label: '🚨 V2V DENM: Siren Alert',
        isEmergency: true,
      );
    }
  }

  void _drawDataBeam({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required Color color,
    required double cycle,
    required String label,
    bool isEmergency = false,
  }) {
    // Animated glowing line
    final beamPaint = Paint()
      ..color = color.withValues(alpha: isEmergency ? 0.85 : 0.5)
      ..strokeWidth = isEmergency ? 2.5 : 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, beamPaint);

    // Flying Data Packet Dot along the beam
    final packetProgress = (cycle * 5.0) % 1.0;
    final packetPos = Offset(
      from.dx + (to.dx - from.dx) * packetProgress,
      from.dy + (to.dy - from.dy) * packetProgress,
    );

    canvas.drawCircle(
      packetPos,
      isEmergency ? 5.0 : 3.5,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  // 🚦 Overhead Smart Traffic Signal Gantry
  void _drawTrafficSignalGantry(Canvas canvas, double cx, bool isBlinkingRed, double anim) {
    const double gantryY = 56.0;

    final isBlinkOn = isBlinkingRed && ((anim * 20).floor() % 2 == 0);
    final signalColor = isBlinkingRed
        ? (isBlinkOn ? const Color(0xFFEF4444) : Colors.black45)
        : const Color(0xFF22C55E);

    // Gantry Box
    final boxRect = Rect.fromCenter(center: Offset(cx, gantryY), width: 220, height: 28);
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(8)), Paint()..color = const Color(0xFF0F172A));

    // Signal Light Bulb
    canvas.drawCircle(
      Offset(cx - 75, gantryY),
      8.5,
      Paint()
        ..color = signalColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isBlinkOn ? 6 : 2),
    );

    // Gantry Text
    final tp = TextPainter(
      text: TextSpan(
        text: isBlinkingRed ? '🔴 PREEMPTION: HOLD CROSS' : '🟢 SPaT: GREEN WAVE (CLEAR)',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - 56, gantryY - tp.height * 0.5));
  }

  // 🚗 Vehicle Painter
  void _drawCar({
    required Canvas canvas,
    required Offset pos,
    required Color bodyColor,
    required Color roofColor,
    required String label,
    required bool hasRightBlinker,
    bool isFlaggedAnomaly = false,
  }) {
    const double w = 42.0;
    const double h = 68.0;

    // Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 5), width: w * 1.25, height: h * 0.95),
      Paint()..color = Colors.black26,
    );

    // Car Body Chassis
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = bodyColor);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = isFlaggedAnomaly ? const Color(0xFFEF4444) : Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFlaggedAnomaly ? 2.0 : 1.2,
    );

    // Roof & Glass
    final roofRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w * 0.68, height: h * 0.52),
      const Radius.circular(4),
    );
    canvas.drawRRect(roofRRect, Paint()..color = roofColor);

    // Roof V2X Shark-Fin Antenna with Wireless Ripple Dot
    canvas.drawCircle(Offset(pos.dx, pos.dy + 8), 3.0, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(pos.dx, pos.dy + 8),
      6.0,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Headlights
    canvas.drawCircle(Offset(pos.dx - 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(pos.dx + 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));

    // Blinking Turn Signal Indicator (Right side)
    if (hasRightBlinker) {
      canvas.drawCircle(
        Offset(pos.dx + 18, pos.dy - (h * 0.3)),
        6.0,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Floating Badge
    _drawBadge(canvas, pos.translate(0, -h * 0.68), label, isFlaggedAnomaly ? const Color(0xFFDC2626) : bodyColor);
  }

  // 🚑 Ambulance Painter
  void _drawAmbulance({
    required Canvas canvas,
    required Offset pos,
    required String label,
    required double cycle,
  }) {
    const double w = 48.0;
    const double h = 82.0;

    // Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 6), width: w * 1.25, height: h * 0.95),
      Paint()..color = Colors.black38,
    );

    // Ambulance Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = Colors.white);
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.stroke..strokeWidth = 2.2);

    // Red Cross on Roof
    final crossPaint = Paint()..color = const Color(0xFFDC2626)..strokeWidth = 4.5;
    canvas.drawLine(Offset(pos.dx - 9, pos.dy), Offset(pos.dx + 9, pos.dy), crossPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 9), Offset(pos.dx, pos.dy + 9), crossPaint);

    // Alternating Red & Blue Strobe Siren Lights
    final isBlue = ((cycle * 24).floor() % 2) == 0;
    final strobe1 = isBlue ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    final strobe2 = isBlue ? const Color(0xFFDC2626) : const Color(0xFF2563EB);

    canvas.drawCircle(Offset(pos.dx - 12, pos.dy - (h * 0.25)), 7.0, Paint()..color = strobe1..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(pos.dx + 12, pos.dy - (h * 0.25)), 7.0, Paint()..color = strobe2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Floating Label
    _drawBadge(canvas, pos.translate(0, -h * 0.68), label, const Color(0xFFDC2626));
  }

  void _drawBadge(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(color: color, fontSize: 10.0, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = Rect.fromCenter(center: center, width: tp.width + 16, height: tp.height + 7);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(6)), Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, center.translate(-tp.width * 0.5, -tp.height * 0.5));
  }

  @override
  bool shouldRepaint(covariant _VanetSimulationPainter oldDelegate) => true;
}
