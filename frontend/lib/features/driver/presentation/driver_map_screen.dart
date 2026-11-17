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

  // --- Active Interactive Control Selection ---
  // 'host' = user controls purple Host car
  // 'challenger' = user controls red/other challenger car
  String _activeControl = 'host';
  String? _currentlyDragging; // 'host' or 'challenger'
  bool _aiAutopilot = true; // Auto evasive dodge vs pure manual driver control

  // Challenger Vehicle State
  Offset? _interactiveCarPos;
  String _interactiveCarType = 'speed_attack'; // 'civilian', 'speed_attack', 'gps_spoof', 'ambulance'
  String _interactiveCarLabel = 'ATK-707 (Speed Anomaly)';
  double _interactiveCarSpeed = 135.0; // km/h

  // Host Car Physical State (Purple-Blue, 'Host')
  double _trainedCarLaneOffset = 0.0; // Target X: -110 (Lane 1), 0 (Lane 2), 110 (Lane 3)
  double _trainedCarCurrentX = 0.0;   // Smoothly interpolated position
  double _trainedCarSpeed = 60.0;     // km/h
  int _hostLaneIndex = 0;             // -1 = Left, 0 = Center, 1 = Right
  int _dodgeCooldownTicks = 0;        // Latching counter to prevent lane-hunting/shaking

  bool _isEmergencyBraking = false;
  bool _isDodging = false;
  int _dodgeDirection = 0; // -1 = Left, +1 = Right
  String _aiDecision = 'V2X CRUISE: SAFE HEADWAY VERIFIED';
  Color _aiDecisionColor = const Color(0xFF059669);

  // Mathematical Beta-Distribution Trust State: T = alpha / (alpha + beta)
  double _alpha = 88.0;
  double _beta = 12.0;
  double _liveTrustScore = 88.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addListener(_onTick)..repeat();
  }

  @override
  void dispose() {
    _animController.removeListener(_onTick);
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

  // --- Real-Time AI Autonomous Reaction Loop (With State Hysteresis) ---
  void _onTick() {
    if (!mounted) return;
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 800);
    final cx = size.width * 0.5;
    final playerY = size.height * 0.55;

    // Initialize challenger car position on first tick if null
    _interactiveCarPos ??= Offset(cx, size.height * 0.30);

    final targetPos = _interactiveCarPos!;
    final playerPos = Offset(cx + _trainedCarCurrentX, playerY);

    // 1. Calculate Relative Kinematics
    final dx = targetPos.dx - playerPos.dx;
    final dy = targetPos.dy - playerPos.dy; // Negative = Ahead, Positive = Behind
    final distPixels = math.sqrt(dx * dx + dy * dy);
    final distMeters = (distPixels / 4.5).clamp(2.0, 150.0);

    // 2. Evaluate Anomaly & Compute Mathematical Beta Trust
    if (_interactiveCarType == 'speed_attack') {
      _alpha = 25.0;
      _beta = 75.0;
      _liveTrustScore = (_alpha / (_alpha + _beta)) * 100.0; // 25% Untrusted
    } else if (_interactiveCarType == 'gps_spoof') {
      _alpha = 15.0;
      _beta = 85.0;
      _liveTrustScore = (_alpha / (_alpha + _beta)) * 100.0; // 15% Rogue
    } else if (_interactiveCarType == 'ambulance') {
      _alpha = 99.0;
      _beta = 1.0;
      _liveTrustScore = 99.0; // Authenticated PKI
    } else {
      _alpha = 94.0;
      _beta = 6.0;
      _liveTrustScore = (_alpha / (_alpha + _beta)) * 100.0; // 94% Trusted
    }

    // 3. Robust Autonomous Reaction Logic (Fixed: Zero Shaking)
    // Identify which discrete lane the Challenger is in: -1 (Left), 0 (Center), 1 (Right)
    final roadWidth = math.min(size.width * 0.90, 340.0);
    final laneWidth = roadWidth / 3.0;
    final challengerLaneIndex = ((targetPos.dx - cx) / (laneWidth * 0.75)).round().clamp(-1, 1);
    final isSameLane = challengerLaneIndex == _hostLaneIndex;
    final isAheadDangerous = isSameLane && dy < 0 && dy > -180.0;
    final isCritClose = isSameLane && dy < 0 && dy > -65.0;

    if (_aiAutopilot && _currentlyDragging != 'host') {
      if (_interactiveCarType == 'ambulance') {
        // Preemption Protocol: Siren detected -> Yield to Right Lane (Lane 3)
        _hostLaneIndex = 1;
        _trainedCarLaneOffset = laneWidth;
        _isDodging = true;
        _dodgeDirection = 1;
        _isEmergencyBraking = false;
        _trainedCarSpeed = 45.0;
        _aiDecision = 'PREEMPTION YIELD: CLEARING EXPRESS CORRIDOR';
        _aiDecisionColor = const Color(0xFF0284C7);
      } else if (isCritClose) {
        // Critical collision hazard: Emergency Brake
        _isEmergencyBraking = true;
        _trainedCarSpeed = 0.0;
        _aiDecision = 'COLLISION THREAT: EMERGENCY BRAKE ACTIVATED';
        _aiDecisionColor = const Color(0xFFDC2626);
      } else if (isAheadDangerous) {
        // Threat ahead in same lane! Pick an open lane and LATCH to it
        if (_dodgeCooldownTicks <= 0) {
          if (_hostLaneIndex == 0) {
            // In center -> swerve left if clear, otherwise right
            _hostLaneIndex = (targetPos.dx >= cx) ? -1 : 1;
          } else if (_hostLaneIndex == -1) {
            _hostLaneIndex = 0; // Return toward center/right
          } else {
            _hostLaneIndex = 0; // Return toward center/left
          }
          // Cooldown locks this lane choice for 40 ticks (~0.7s) to guarantee zero jitter
          _dodgeCooldownTicks = 40;
        }

        _trainedCarLaneOffset = _hostLaneIndex * laneWidth;
        _isDodging = true;
        _dodgeDirection = _hostLaneIndex;
        _isEmergencyBraking = false;
        _trainedCarSpeed = 52.0;
        _aiDecision = _hostLaneIndex < 0
            ? 'AI EVASIVE DODGE: SWERVING TO LEFT LANE'
            : 'AI EVASIVE DODGE: SWERVING TO RIGHT LANE';
        _aiDecisionColor = const Color(0xFFEA580C);
      } else {
        // Road is clear
        if (_dodgeCooldownTicks > 0) {
          _dodgeCooldownTicks--;
        } else {
          _isDodging = false;
          _isEmergencyBraking = false;
          _dodgeDirection = 0;
          _trainedCarSpeed = 60.0;

          // Safely return to center lane when obstacle is behind or far away
          if (_interactiveCarType != 'ambulance' && (dy > 40.0 || distMeters > 35.0)) {
            _hostLaneIndex = 0;
            _trainedCarLaneOffset = 0.0;
          }
        }

        if (_liveTrustScore < 40.0) {
          _aiDecision = 'MALICIOUS NODE FLAGGED: SAFE BUFFER MAINTAINED';
          _aiDecisionColor = const Color(0xFFDC2626);
        } else {
          _aiDecision = 'NORMAL CRUISE: SAFE HEADWAY VERIFIED';
          _aiDecisionColor = const Color(0xFF059669);
        }
      }
    }

    // Smooth physical position interpolation (spring-damping)
    if (_currentlyDragging != 'host') {
      _trainedCarCurrentX += (_trainedCarLaneOffset - _trainedCarCurrentX) * 0.12;
    }

    setState(() {});
  }

  // --- Smart Touch & Drag Handlers: Move whichever car you touch! ---
  void _onPanStart(DragStartDetails details) {
    final size = MediaQuery.of(context).size;
    final cx = size.width * 0.5;
    final playerY = size.height * 0.55;
    final hostPos = Offset(cx + _trainedCarCurrentX, playerY);
    final targetPos = _interactiveCarPos ?? Offset(cx, size.height * 0.30);

    final dHost = (details.localPosition - hostPos).distance;
    final dChallenger = (details.localPosition - targetPos).distance;

    // If touch is closer to Host (or within 75px), user is directly touching Host!
    if (dHost < 75.0 || (dHost < dChallenger && _activeControl == 'host')) {
      _currentlyDragging = 'host';
      _activeControl = 'host';
    } else {
      _currentlyDragging = 'challenger';
      _activeControl = 'challenger';
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final cx = size.width * 0.5;
    final roadWidth = math.min(size.width * 0.90, 340.0);
    final laneWidth = roadWidth / 3.0;
    final maxOffset = (roadWidth * 0.5) - 30.0;

    if (_currentlyDragging == 'host') {
      // Direct Touch Drag on Host Car!
      setState(() {
        _trainedCarCurrentX = (details.localPosition.dx - cx).clamp(-maxOffset, maxOffset);
        _trainedCarLaneOffset = _trainedCarCurrentX;
        _hostLaneIndex = (_trainedCarCurrentX / (laneWidth * 0.75)).round().clamp(-1, 1);
      });
    } else {
      // Direct Touch Drag on Challenger Car!
      setState(() {
        _interactiveCarPos = Offset(
          details.localPosition.dx.clamp(30.0, size.width - 30.0),
          details.localPosition.dy.clamp(80.0, size.height - 120.0),
        );
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _currentlyDragging = null;
    setState(() {});
  }

  // --- D-Pad Steering Controls ---
  void _moveCar(double dX, double dY) {
    final size = MediaQuery.of(context).size;
    final cx = size.width * 0.5;
    final roadWidth = math.min(size.width * 0.90, 340.0);
    final laneWidth = roadWidth / 3.0;

    if (_activeControl == 'host') {
      // Steer Host!
      setState(() {
        if (dX != 0) {
          // Lane Shift Left / Right
          _hostLaneIndex = (_hostLaneIndex + (dX > 0 ? 1 : -1)).clamp(-1, 1);
          _trainedCarLaneOffset = _hostLaneIndex * laneWidth;
          _trainedCarCurrentX = _trainedCarLaneOffset;
        }
        if (dY < 0) {
          _trainedCarSpeed = (_trainedCarSpeed + 10.0).clamp(0.0, 120.0);
        } else if (dY > 0) {
          _trainedCarSpeed = (_trainedCarSpeed - 15.0).clamp(0.0, 120.0);
        }
      });
    } else {
      // Steer Challenger!
      if (_interactiveCarPos == null) return;
      setState(() {
        _interactiveCarPos = Offset(
          (_interactiveCarPos!.dx + dX).clamp(30.0, size.width - 30.0),
          (_interactiveCarPos!.dy + dY).clamp(80.0, size.height - 120.0),
        );
      });
    }
  }

  void _selectVehicleType(String type, String label, double speed) {
    setState(() {
      _interactiveCarType = type;
      _interactiveCarLabel = label;
      _interactiveCarSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final size = MediaQuery.of(context).size;
    final cx = size.width * 0.5;

    final playerPos = Offset(cx + _trainedCarCurrentX, size.height * 0.55);
    final targetPos = _interactiveCarPos ?? Offset(cx, size.height * 0.30);
    final distMeters = (math.sqrt(math.pow(targetPos.dx - playerPos.dx, 2) + math.pow(targetPos.dy - playerPos.dy, 2)) / 4.5).clamp(2.0, 150.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. INTERACTIVE TOUCH CANVAS: Direct touch on Host OR Challenger!
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: Size.infinite,
              painter: _VanetInteractivePainter(
                cycle: _animController.value,
                trainedCarX: _trainedCarCurrentX,
                trainedCarSpeed: _trainedCarSpeed,
                isBraking: _isEmergencyBraking,
                isDodging: _isDodging,
                dodgeDirection: _dodgeDirection,
                testCarPos: targetPos,
                testCarType: _interactiveCarType,
                testCarLabel: _interactiveCarLabel,
                testCarTrust: _liveTrustScore,
                activeControl: _activeControl,
                currentlyDragging: _currentlyDragging,
                baseTrust: driverState.trustScore,
              ),
            ),
          ),

          // 2. TOP AI STATUS & ACTIVE CAR CONTROL SELECTOR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Decision Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _aiDecisionColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isEmergencyBraking
                                ? Icons.warning_rounded
                                : (_isDodging ? Icons.swap_horiz_rounded : Icons.verified_user_rounded),
                            color: _aiDecisionColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _aiDecisionColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _isEmergencyBraking
                                            ? 'EMERGENCY'
                                            : (_isDodging ? 'REACTION' : 'MONITORING'),
                                        style: GoogleFonts.outfit(
                                          color: _aiDecisionColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'HOST',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.0,
                                      color: const Color(0xFF7C3AED),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _aiDecision,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${distMeters.toStringAsFixed(1)}m | ${_trainedCarSpeed.toStringAsFixed(0)} km/h',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  color: const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Vehicle Spawner Modal
                        InkWell(
                          onTap: _showVehiclePickerModal,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE45D3F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Node',
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

                  const SizedBox(height: 8),

                  // ACTIVE CAR CONTROL SWITCHER & AUTOPILOT TOGGLE (Responsive Wrap)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CONTROL:',
                              style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            // Host Toggle Pill
                            InkWell(
                              onTap: () => setState(() => _activeControl = 'host'),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _activeControl == 'host' ? const Color(0xFF7C3AED) : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _activeControl == 'host' ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 12, color: _activeControl == 'host' ? Colors.white : const Color(0xFF7C3AED)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Host',
                                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: _activeControl == 'host' ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Challenger Toggle Pill
                            InkWell(
                              onTap: () => setState(() => _activeControl = 'challenger'),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _activeControl == 'challenger' ? const Color(0xFFDC2626) : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _activeControl == 'challenger' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 12, color: _activeControl == 'challenger' ? Colors.white : const Color(0xFFDC2626)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Challenger',
                                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: _activeControl == 'challenger' ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Autopilot Toggle
                        InkWell(
                          onTap: () => setState(() => _aiAutopilot = !_aiAutopilot),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _aiAutopilot ? const Color(0xFF059669).withOpacity(0.12) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _aiAutopilot ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _aiAutopilot ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                                  size: 12,
                                  color: _aiAutopilot ? const Color(0xFF059669) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _aiAutopilot ? 'AI Autopilot: ON' : 'AI Autopilot: OFF',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _aiAutopilot ? const Color(0xFF059669) : const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING ON-SCREEN STEERING CONTROLS (D-PAD)
          Positioned(
            right: 14,
            bottom: 96,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeControl == 'host' ? 'STEER HOST' : 'STEER CHALLENGER',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _activeControl == 'host' ? const Color(0xFF7C3AED) : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _dpadBtn(Icons.arrow_upward_rounded, () => _moveCar(0, -35), 'Forward / Accel'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dpadBtn(Icons.arrow_back_rounded, () => _moveCar(-45, 0), 'Shift Left'),
                      const SizedBox(width: 8),
                      _dpadBtn(Icons.arrow_forward_rounded, () => _moveCar(45, 0), 'Shift Right'),
                    ],
                  ),
                  _dpadBtn(Icons.arrow_downward_rounded, () => _moveCar(0, 35), 'Brake / Reverse'),
                ],
              ),
            ),
          ),

          // 4. BOTTOM VANET HIGHWAY METRICS HUD (Horizontal Scrollable for Mobile)
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _statTile('ACTIVE DRIVER', _activeControl == 'host' ? 'Host (Purple)' : 'Challenger', const Color(0xFF0F172A), Icons.touch_app_rounded),
                    const SizedBox(width: 14),
                    Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 14),
                    _statTile('DISTANCE', '${distMeters.toStringAsFixed(1)} m', distMeters < 12 ? const Color(0xFFDC2626) : const Color(0xFF0284C7), Icons.straighten_rounded),
                    const SizedBox(width: 14),
                    Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 14),
                    _statTile('EVALUATED TRUST', '${_liveTrustScore.toStringAsFixed(0)}%', _liveTrustScore >= 75 ? const Color(0xFF059669) : const Color(0xFFDC2626), Icons.shield_rounded),
                    const SizedBox(width: 14),
                    Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 14),
                    _statTile('AI REACTION', _isEmergencyBraking ? 'BRAKING' : (_isDodging ? 'DODGING' : 'CRUISING'), _isEmergencyBraking ? const Color(0xFFDC2626) : (_isDodging ? const Color(0xFFEA580C) : const Color(0xFF059669)), Icons.psychology_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dpadBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF334155)),
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
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 9.0, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showVehiclePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Test Vehicle to Challenge Host',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                Text(
                  'Choose a vehicle to spawn and test Host\'s autonomous dodge reaction.',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                _pickerOption(
                  icon: Icons.speed_rounded,
                  color: const Color(0xFFDC2626),
                  title: 'Speed Anomaly Attacker (ATK-707)',
                  subtitle: 'Velocity: 140 km/h | dv/dt > 8.5 m/s2 | AI Trust: 25% (Untrusted)',
                  onTap: () {
                    _selectVehicleType('speed_attack', 'ATK-707 (Speed Anomaly)', 140.0);
                    Navigator.pop(ctx);
                  },
                ),
                _pickerOption(
                  icon: Icons.gps_off_rounded,
                  color: const Color(0xFF991B1B),
                  title: 'Position Spoofing Rogue (GHOST-909)',
                  subtitle: 'Coordinates jump 65m | GPS Plausibility Failure | AI Trust: 15% (Rogue)',
                  onTap: () {
                    _selectVehicleType('gps_spoof', 'GHOST-909 (GPS Spoof)', 70.0);
                    Navigator.pop(ctx);
                  },
                ),
                _pickerOption(
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFF0284C7),
                  title: 'Emergency Ambulance (AMB-1122)',
                  subtitle: 'PKI Signed Siren Beacon | Preemption Active | AI Trust: 99% (Priority)',
                  onTap: () {
                    _selectVehicleType('ambulance', 'AMB-1122 (Ambulance)', 95.0);
                    Navigator.pop(ctx);
                  },
                ),
                _pickerOption(
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                  title: 'Cooperative Civilian Vehicle (CIV-204)',
                  subtitle: 'Normal 10Hz CAMs | Compliant Headway | AI Trust: 94% (Trusted)',
                  onTap: () {
                    _selectVehicleType('civilian', 'CIV-204 (Civilian)', 55.0);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

// ============================================================================
// Real-Time VANET Interactive Highway Custom Painter
// ============================================================================
class _VanetInteractivePainter extends CustomPainter {
  final double cycle;
  final double trainedCarX;
  final double trainedCarSpeed;
  final bool isBraking;
  final bool isDodging;
  final int dodgeDirection;
  final Offset testCarPos;
  final String testCarType;
  final String testCarLabel;
  final double testCarTrust;
  final String activeControl;
  final String? currentlyDragging;
  final double baseTrust;

  _VanetInteractivePainter({
    required this.cycle,
    required this.trainedCarX,
    required this.trainedCarSpeed,
    required this.isBraking,
    required this.isDodging,
    required this.dodgeDirection,
    required this.testCarPos,
    required this.testCarType,
    required this.testCarLabel,
    required this.testCarTrust,
    required this.activeControl,
    required this.currentlyDragging,
    required this.baseTrust,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;

    // 1. Terrain Grass Lawn
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF0FDF4));

    // 2. 3-Lane Smart Highway (Dynamic Width for Responsive Mobile Screens)
    final double roadWidth = math.min(size.width * 0.90, 340.0);
    final double laneWidth = roadWidth / 3.0;
    final roadRect = Rect.fromCenter(center: Offset(cx, size.height * 0.5), width: roadWidth, height: size.height);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF334155));

    // Curbs
    final curbPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 4.0;
    canvas.drawLine(Offset(cx - roadWidth * 0.5, 0), Offset(cx - roadWidth * 0.5, size.height), curbPaint);
    canvas.drawLine(Offset(cx + roadWidth * 0.5, 0), Offset(cx + roadWidth * 0.5, size.height), curbPaint);

    // 3. Moving Lane Dashed Dividers
    final animSpeed = isBraking ? 0.0 : (trainedCarSpeed / 60.0);
    _drawMovingDashedLine(canvas, cx - laneWidth * 0.5, size.height, (cycle * animSpeed) % 1.0);
    _drawMovingDashedLine(canvas, cx + laneWidth * 0.5, size.height, (cycle * animSpeed) % 1.0);

    // 4. Directional Road Markings
    _drawDirectionalArrows(canvas, cx, size.height, (cycle * animSpeed) % 1.0);

    // 5. Positions
    final playerPos = Offset(cx + trainedCarX, size.height * 0.55);

    // 6. Draw 360-Degree AI Perception Scanner from Host
    _drawAiPerceptionScanner(canvas, playerPos, testCarPos, cycle);

    // 7. Distance & Target Vector Line
    _drawTargetVectorLine(canvas, playerPos, testCarPos, testCarTrust);

    // 8. Draw Trained Solo Host Vehicle (Host) - Purple-Blue
    _drawHostCar(
      canvas: canvas,
      pos: playerPos,
      bodyColor: const Color(0xFF7C3AED),
      roofColor: const Color(0xFF4F46E5),
      label: 'Host',
      isBraking: isBraking,
      isDodging: isDodging,
      dodgeDirection: dodgeDirection,
      isSelected: activeControl == 'host',
      isBeingDragged: currentlyDragging == 'host',
    );

    // 9. Draw Challenger Test Vehicle
    if (testCarType == 'ambulance') {
      _drawAmbulance(
        canvas: canvas,
        pos: testCarPos,
        label: testCarLabel,
        isSelected: activeControl == 'challenger',
        isBeingDragged: currentlyDragging == 'challenger',
      );
    } else {
      _drawTestCar(
        canvas: canvas,
        pos: testCarPos,
        label: testCarLabel,
        trustScore: testCarTrust,
        isSelected: activeControl == 'challenger',
        isBeingDragged: currentlyDragging == 'challenger',
        type: testCarType,
      );
    }
  }

  // --- Dynamic AI Perception Scanner ---
  void _drawAiPerceptionScanner(Canvas canvas, Offset host, Offset target, double anim) {
    final radarPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(host, 160.0, radarPaint);

    final pulseRadius = 60.0 + (anim * 100.0);
    final wavePaint = Paint()
      ..color = (testCarTrust < 40 ? const Color(0xFFDC2626) : const Color(0xFF7C3AED))
          .withOpacity(((1.0 - anim) * 0.45).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(host, pulseRadius, wavePaint);
  }

  // --- Target Telemetry Vector Line ---
  void _drawTargetVectorLine(Canvas canvas, Offset host, Offset target, double trust) {
    final color = trust >= 75 ? const Color(0xFF059669) : (trust >= 40 ? const Color(0xFFEA580C) : const Color(0xFFDC2626));
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(host, target, linePaint);

    final mid = Offset((host.dx + target.dx) * 0.5, (host.dy + target.dy) * 0.5);
    final distMeters = (math.sqrt(math.pow(target.dx - host.dx, 2) + math.pow(target.dy - host.dy, 2)) / 4.5).clamp(2.0, 150.0);

    final tp = TextPainter(
      text: TextSpan(
        text: '${distMeters.toStringAsFixed(1)}m',
        style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(center: mid, width: tp.width + 12, height: tp.height + 6);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), Paint()..color = Colors.white);
    tp.paint(canvas, mid.translate(-tp.width * 0.5, -tp.height * 0.5));
  }

  // --- Host Car Painter ---
  void _drawHostCar({
    required Canvas canvas,
    required Offset pos,
    required Color bodyColor,
    required Color roofColor,
    required String label,
    required bool isBraking,
    required bool isDodging,
    required int dodgeDirection,
    required bool isSelected,
    required bool isBeingDragged,
  }) {
    const double w = 44.0;
    const double h = 70.0;

    // Selection / Touch Halo Ring
    if (isSelected || isBeingDragged) {
      canvas.drawCircle(
        pos,
        48.0,
        Paint()
          ..color = const Color(0xFF7C3AED).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 5), width: w * 1.25, height: h * 0.95),
      Paint()..color = Colors.black26,
    );

    // Chassis
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = bodyColor);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = isBraking ? const Color(0xFFDC2626) : Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = isBraking ? 2.5 : 1.2,
    );

    // Roof & Glass
    final roofRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w * 0.68, height: h * 0.52),
      const Radius.circular(4),
    );
    canvas.drawRRect(roofRRect, Paint()..color = roofColor);

    // V2X Shark Antenna
    canvas.drawCircle(Offset(pos.dx, pos.dy + 8), 3.0, Paint()..color = Colors.white);

    // Headlights
    canvas.drawCircle(Offset(pos.dx - 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(pos.dx + 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));

    // Emergency Brake Lights
    if (isBraking) {
      final brakePaint = Paint()
        ..color = const Color(0xFFFF0000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(pos.dx - 14, pos.dy + (h * 0.42)), 6.0, brakePaint);
      canvas.drawCircle(Offset(pos.dx + 14, pos.dy + (h * 0.42)), 6.0, brakePaint);
    }

    // Turn Signal Indicators during Dodge
    if (isDodging) {
      final blinkX = dodgeDirection < 0 ? (pos.dx - 18) : (pos.dx + 18);
      canvas.drawCircle(
        Offset(blinkX, pos.dy - (h * 0.3)),
        6.0,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Badge
    _drawBadge(canvas, pos.translate(0, -h * 0.68), label, bodyColor);
  }

  // --- Challenger Test Vehicle Painter ---
  void _drawTestCar({
    required Canvas canvas,
    required Offset pos,
    required String label,
    required double trustScore,
    required bool isSelected,
    required bool isBeingDragged,
    required String type,
  }) {
    const double w = 42.0;
    const double h = 68.0;

    final color = trustScore >= 75
        ? const Color(0xFF059669)
        : (trustScore >= 40 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    // Selection / Dragging Halo Ring
    if (isSelected || isBeingDragged) {
      canvas.drawCircle(
        pos,
        48.0,
        Paint()
          ..color = color.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 5), width: w * 1.25, height: h * 0.95),
      Paint()..color = Colors.black26,
    );

    // Chassis
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = color);

    // Roof Glass
    final roofRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w * 0.68, height: h * 0.52),
      const Radius.circular(4),
    );
    canvas.drawRRect(roofRRect, Paint()..color = Colors.black87);

    // Tail / Head lights
    canvas.drawCircle(Offset(pos.dx - 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(pos.dx + 13, pos.dy - (h * 0.42)), 3.5, Paint()..color = const Color(0xFFFEF08A));

    // Floating Badge
    _drawBadge(canvas, pos.translate(0, -h * 0.68), '$label (${trustScore.toStringAsFixed(0)}%)', color);
  }

  // --- Ambulance Painter ---
  void _drawAmbulance({
    required Canvas canvas,
    required Offset pos,
    required String label,
    required bool isSelected,
    required bool isBeingDragged,
  }) {
    const double w = 48.0;
    const double h = 82.0;

    // Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 6), width: w * 1.25, height: h * 0.95),
      Paint()..color = Colors.black38,
    );

    // Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = Colors.white);
    canvas.drawRRect(bodyRRect, Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Red Cross
    final crossPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRect(Rect.fromCenter(center: pos, width: 7, height: 24), crossPaint);
    canvas.drawRect(Rect.fromCenter(center: pos, width: 24, height: 7), crossPaint);

    // Siren
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 16),
      8.0,
      Paint()
        ..color = const Color(0xFF0284C7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _drawBadge(canvas, pos.translate(0, -h * 0.68), label, const Color(0xFFDC2626));
  }

  // --- Badge Helper ---
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
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, center.translate(-tp.width * 0.5, -tp.height * 0.5));
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
      final p = Path();
      p.moveTo(cx - 8, y + 10);
      p.lineTo(cx, y);
      p.lineTo(cx + 8, y + 10);
      canvas.drawPath(p, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VanetInteractivePainter oldDelegate) => true;
}
