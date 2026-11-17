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

  // --- Interactive Vehicle & AI Testing State ---
  // Position of user-controlled / spawned vehicle (null = auto-looping scenario)
  Offset? _interactiveCarPos;
  String _interactiveCarType = 'speed_attack'; // 'civilian', 'speed_attack', 'gps_spoof', 'ambulance'
  String _interactiveCarLabel = 'ATK-707 (Speed Anomaly)';
  double _interactiveCarSpeed = 135.0; // km/h
  bool _isDragging = false;
  bool _showDpad = true;

  // Trained Host Car (V-101) Dynamic Physical State
  double _trainedCarLaneOffset = 0.0; // Target X offset: -110 (Lane 1), 0 (Lane 2), 110 (Lane 3)
  double _trainedCarCurrentX = 0.0; // Smoothly interpolated position
  double _trainedCarSpeed = 60.0; // km/h
  bool _isEmergencyBraking = false;
  bool _isDodging = false;
  int _dodgeDirection = 0; // -1 = Left, +1 = Right
  String _aiDecision = 'V2X CRUISE: MONITORING 10Hz BSMs';
  Color _aiDecisionColor = const Color(0xFF059669);

  // Mathematical Beta-Distribution Trust State: T = alpha / (alpha + beta)
  double _alpha = 88.0; // Positive consistent packets
  double _beta = 12.0;  // Anomaly penalties
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

  // --- Real-Time AI Autonomous Reaction Loop ---
  void _onTick() {
    if (!mounted) return;
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(400, 800);
    final cx = size.width * 0.5;
    final playerY = size.height * 0.55;

    // Initialize interactive car position on first tick if null
    _interactiveCarPos ??= Offset(cx, size.height * 0.32);

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
      // Civilian
      _alpha = 94.0;
      _beta = 6.0;
      _liveTrustScore = (_alpha / (_alpha + _beta)) * 100.0; // 94% Trusted
    }

    // 3. AI Autonomous Reaction Engine
    // Check if test vehicle is in our lane or cutting into our path
    final isSameLane = dx.abs() < 55.0;
    final isAheadDangerous = dy < 0 && dy > -150.0; // Ahead within 150px
    final isTailgatingDangerous = dy > 0 && dy < 110.0; // Behind within 110px

    if (_interactiveCarType == 'ambulance') {
      // Preemption Protocol: Emergency Siren detected -> Yield to Right Lane (Lane 3)
      _trainedCarLaneOffset = 110.0;
      _isDodging = true;
      _dodgeDirection = 1;
      _isEmergencyBraking = false;
      _trainedCarSpeed = 45.0;
      _aiDecision = 'PREEMPTION YIELD: CLEARING EXPRESS CORRIDOR';
      _aiDecisionColor = const Color(0xFF0284C7);
    } else if (isSameLane && (isAheadDangerous || isTailgatingDangerous)) {
      // Threat in current lane: Autonomous Decision
      if (distMeters < 8.0) {
        // Critical Proximity: Emergency Brake + Collision Avoidance
        _isEmergencyBraking = true;
        _trainedCarSpeed = 0.0;
        _aiDecision = 'COLLISION THREAT: EMERGENCY BRAKE ACTIVATED';
        _aiDecisionColor = const Color(0xFFDC2626);
      } else {
        // Safe Dodge: Evaluate Adjacent Lanes for Evasive Lane Change
        _isEmergencyBraking = false;
        _trainedCarSpeed = 52.0;

        // Try Left Lane (cx - 110) if not already on left curb
        if (_trainedCarLaneOffset >= 0.0) {
          _trainedCarLaneOffset = -110.0;
          _isDodging = true;
          _dodgeDirection = -1;
          _aiDecision = 'AI EVASIVE DODGE: SWERVING TO LEFT LANE';
          _aiDecisionColor = const Color(0xFFEA580C);
        } else {
          // If already in Left Lane, Dodge Right
          _trainedCarLaneOffset = 110.0;
          _isDodging = true;
          _dodgeDirection = 1;
          _aiDecision = 'AI EVASIVE DODGE: SWERVING TO RIGHT LANE';
          _aiDecisionColor = const Color(0xFFEA580C);
        }
      }
    } else {
      // Path Clear or Lateral Offset Safe
      _isEmergencyBraking = false;
      _isDodging = false;
      _dodgeDirection = 0;
      _trainedCarSpeed = 60.0;

      // Gradually return to Center Cruise Lane (Lane 2) when threat is clear
      if (_interactiveCarType != 'ambulance' && distMeters > 30.0) {
        _trainedCarLaneOffset = 0.0;
      }

      if (_liveTrustScore < 40.0) {
        _aiDecision = 'MALICIOUS NODE FLAGGED: SAFE BUFFER MAINTAINED';
        _aiDecisionColor = const Color(0xFFDC2626);
      } else {
        _aiDecision = 'NORMAL CRUISE: SAFE HEADWAY VERIFIED';
        _aiDecisionColor = const Color(0xFF059669);
      }
    }

    // Smooth physical position interpolation (spring damping)
    _trainedCarCurrentX += (_trainedCarLaneOffset - _trainedCarCurrentX) * 0.14;

    setState(() {});
  }

  // --- Touch & Drag Handlers ---
  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _interactiveCarPos = details.localPosition;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _interactiveCarPos = details.localPosition;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    setState(() {});
  }

  // --- D-Pad Steering Triggers ---
  void _moveCar(double dX, double dY) {
    if (_interactiveCarPos == null) return;
    setState(() {
      _interactiveCarPos = Offset(
        (_interactiveCarPos!.dx + dX).clamp(40.0, MediaQuery.of(context).size.width - 40.0),
        (_interactiveCarPos!.dy + dY).clamp(80.0, MediaQuery.of(context).size.height - 120.0),
      );
    });
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

    // Relative distance calculation
    final playerPos = Offset(cx + _trainedCarCurrentX, size.height * 0.55);
    final targetPos = _interactiveCarPos ?? Offset(cx, size.height * 0.32);
    final distMeters = (math.sqrt(math.pow(targetPos.dx - playerPos.dx, 2) + math.pow(targetPos.dy - playerPos.dy, 2)) / 4.5).clamp(2.0, 150.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. INTERACTIVE TOUCH CANVAS: Drag & Steer test car across highway
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
                isDragging: _isDragging,
                baseTrust: driverState.trustScore,
              ),
            ),
          ),

          // 2. TOP AI STATUS & INTERACTIVE ACTION HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main AI Header Card
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _aiDecisionColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isEmergencyBraking
                                ? Icons.warning_rounded
                                : (_isDodging ? Icons.swap_horiz_rounded : Icons.verified_user_rounded),
                            color: _aiDecisionColor,
                            size: 22,
                          ),
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
                                      color: _aiDecisionColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _isEmergencyBraking
                                          ? 'EMERGENCY ACTION'
                                          : (_isDodging ? 'AUTONOMOUS REACTION' : 'ONLINE MONITORING'),
                                      style: GoogleFonts.outfit(
                                        color: _aiDecisionColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'HOST (TRAINED)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      color: const Color(0xFF7C3AED),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _aiDecision,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.0,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Distance: ${distMeters.toStringAsFixed(1)}m | Host Speed: ${_trainedCarSpeed.toStringAsFixed(0)} km/h',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Spawn / Change Vehicle Button
                        ElevatedButton.icon(
                          onPressed: _showVehiclePickerModal,
                          icon: const Icon(Icons.add_road_rounded, size: 15),
                          label: const Text('Add Vehicle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE45D3F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Real Mathematical Trust & Anomaly Inspector Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _formulaPill('BETA TRUST', 'T = ${_alpha.toInt()} / (${_alpha.toInt()} + ${_beta.toInt()}) = ${_liveTrustScore.toStringAsFixed(0)}%', _liveTrustScore >= 75 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                        Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                        _formulaPill('AI CLASSIFIER', _liveTrustScore >= 75 ? 'TRUSTED (CAM Valid)' : (_liveTrustScore >= 40 ? 'SUSPICIOUS (Outlier)' : 'ROGUE (Blacklisted)'), _liveTrustScore >= 75 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                        Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                        _formulaPill('TOUCH CONTROL', _isDragging ? 'DRAGGING ACTIVE' : 'TOUCH TO DRAG', const Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING ON-SCREEN STEERING CONTROLS (D-PAD)
          if (_showDpad)
            Positioned(
              right: 14,
              bottom: 84,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STEER / DODGE TEST',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    // Forward
                    _dpadBtn(Icons.arrow_upward_rounded, () => _moveCar(0, -35), 'Forward'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Left Cut
                        _dpadBtn(Icons.arrow_back_rounded, () => _moveCar(-45, 0), 'Cut Left'),
                        const SizedBox(width: 8),
                        // Right Cut
                        _dpadBtn(Icons.arrow_forward_rounded, () => _moveCar(45, 0), 'Cut Right'),
                      ],
                    ),
                    // Reverse / Cut in front
                    _dpadBtn(Icons.arrow_downward_rounded, () => _moveCar(0, 35), 'Cut Behind'),
                  ],
                ),
              ),
            ),

          // 4. BOTTOM VANET HIGHWAY METRICS HUD
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  _statTile('TARGET NODE', _interactiveCarLabel.split(' ').first, const Color(0xFF0F172A), Icons.directions_car_rounded),
                  Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                  _statTile('DISTANCE', '${distMeters.toStringAsFixed(1)} m', distMeters < 12 ? const Color(0xFFDC2626) : const Color(0xFF0284C7), Icons.straighten_rounded),
                  Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                  _statTile('EVALUATED TRUST', '${_liveTrustScore.toStringAsFixed(0)}%', _liveTrustScore >= 75 ? const Color(0xFF059669) : const Color(0xFFDC2626), Icons.shield_rounded),
                  Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),
                  _statTile('AI REACTION', _isEmergencyBraking ? 'BRAKING' : (_isDodging ? 'DODGING' : 'CRUISING'), _isEmergencyBraking ? const Color(0xFFDC2626) : (_isDodging ? const Color(0xFFEA580C) : const Color(0xFF059669)), Icons.psychology_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaPill(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 1),
        Text(val, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
      ],
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Test Vehicle to Challenge Trained Car',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                Text(
                  'Drag the selected car on screen towards V-101 to see how its AI model evaluates trust and triggers evasive actions.',
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
        backgroundColor: color.withValues(alpha: 0.12),
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
  final bool isDragging;
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
    required this.isDragging,
    required this.baseTrust,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;

    // 1. Terrain Grass Lawn
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF0FDF4));

    // 2. 3-Lane Smart Highway (340px wide)
    // Lane 1 (Express / Incident): cx - 110
    // Lane 2 (Main Cruise): cx
    // Lane 3 (Detour / Yield): cx + 110
    const double roadWidth = 340.0;
    final roadRect = Rect.fromCenter(center: Offset(cx, size.height * 0.5), width: roadWidth, height: size.height);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF334155));

    // Highway Curbs
    final curbPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 4.0;
    canvas.drawLine(Offset(cx - roadWidth * 0.5, 0), Offset(cx - roadWidth * 0.5, size.height), curbPaint);
    canvas.drawLine(Offset(cx + roadWidth * 0.5, 0), Offset(cx + roadWidth * 0.5, size.height), curbPaint);

    // 3. Moving Lane Dashed Dividers
    final animSpeed = isBraking ? 0.0 : (trainedCarSpeed / 60.0);
    _drawMovingDashedLine(canvas, cx - 55, size.height, (cycle * animSpeed) % 1.0);
    _drawMovingDashedLine(canvas, cx + 55, size.height, (cycle * animSpeed) % 1.0);

    // 4. Directional Road Markings
    _drawDirectionalArrows(canvas, cx, size.height, (cycle * animSpeed) % 1.0);

    // 5. Positions
    final playerPos = Offset(cx + trainedCarX, size.height * 0.55);

    // 6. Draw 360-Degree AI Perception Scanner Cone & Radar Ring from Trained Car
    _drawAiPerceptionScanner(canvas, playerPos, testCarPos, cycle);

    // 7. Distance & Target Vector Line
    _drawTargetVectorLine(canvas, playerPos, testCarPos, testCarTrust);

    // 8. Draw Trained Solo Host Vehicle (Host) - Purple-Blue
    _drawHostCar(
      canvas: canvas,
      pos: playerPos,
      bodyColor: const Color(0xFF7C3AED), // Royal Purple-Blue
      roofColor: const Color(0xFF4F46E5), // Deep Indigo
      label: 'Host',
      isBraking: isBraking,
      isDodging: isDodging,
      dodgeDirection: dodgeDirection,
    );

    // 9. Draw Interactive Test Vehicle (User-Controlled)
    if (testCarType == 'ambulance') {
      _drawAmbulance(
        canvas: canvas,
        pos: testCarPos,
        label: testCarLabel,
        isDragging: isDragging,
      );
    } else {
      _drawTestCar(
        canvas: canvas,
        pos: testCarPos,
        label: testCarLabel,
        trustScore: testCarTrust,
        isDragging: isDragging,
        type: testCarType,
      );
    }
  }

  // --- Dynamic AI Perception Scanner ---
  void _drawAiPerceptionScanner(Canvas canvas, Offset host, Offset target, double anim) {
    final radarPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // 360 Awareness Field (160px radius)
    canvas.drawCircle(host, 160.0, radarPaint);

    // Pulsing Perception Wave
    final pulseRadius = 60.0 + (anim * 100.0);
    final wavePaint = Paint()
      ..color = (testCarTrust < 40 ? const Color(0xFFDC2626) : const Color(0xFF7C3AED)).withValues(alpha: (1.0 - anim) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(host, pulseRadius, wavePaint);
  }

  // --- Target Telemetry Vector Line ---
  void _drawTargetVectorLine(Canvas canvas, Offset host, Offset target, double trust) {
    final color = trust >= 75 ? const Color(0xFF059669) : (trust >= 40 ? const Color(0xFFEA580C) : const Color(0xFFDC2626));
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(host, target, linePaint);

    // Midpoint distance label
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

  // --- Trained Solo Host Car Painter ---
  void _drawHostCar({
    required Canvas canvas,
    required Offset pos,
    required Color bodyColor,
    required Color roofColor,
    required String label,
    required bool isBraking,
    required bool isDodging,
    required int dodgeDirection,
  }) {
    const double w = 44.0;
    const double h = 70.0;

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

    // Emergency Brake Lights (Glowing Red during collision avoidance)
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

  // --- Interactive Test Vehicle Painter ---
  void _drawTestCar({
    required Canvas canvas,
    required Offset pos,
    required String label,
    required double trustScore,
    required bool isDragging,
    required String type,
  }) {
    const double w = 42.0;
    const double h = 68.0;

    final color = trustScore >= 75
        ? const Color(0xFF059669)
        : (trustScore >= 40 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    // Dragging Glow Ring
    if (isDragging) {
      canvas.drawCircle(
        pos,
        48.0,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
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

    // Touch Drag Target Crosshair Indicator
    canvas.drawCircle(
      pos,
      12.0,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Floating Badge
    _drawBadge(canvas, pos.translate(0, -h * 0.68), '$label (${trustScore.toStringAsFixed(0)}%)', color);
  }

  // --- Ambulance Painter ---
  void _drawAmbulance({
    required Canvas canvas,
    required Offset pos,
    required String label,
    required bool isDragging,
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

    // Flashing Siren
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
        ..color = color.withValues(alpha: 0.5)
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
