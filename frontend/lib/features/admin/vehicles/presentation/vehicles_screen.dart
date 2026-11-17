import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanet_mobile/core/theme/theme.dart';
import 'package:vanet_mobile/features/admin/dashboard/presentation/dashboard_provider.dart';
import 'package:vanet_mobile/core/utils/responsive.dart';

final vehiclesSearchQueryProvider = StateProvider<String>((ref) => '');

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);
    final searchQuery = ref.watch(vehiclesSearchQueryProvider);

    final filteredVehicles = state.vehicles.where((v) {
      return v.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.trustStatus.toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.attackType.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Vehicle Detection & Trust',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          // Add Custom Vehicle for Testing
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddVehicleDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: Column(
            children: [
              // 🔹 Top Info Banner for Evaluators & Testers
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live Test Lab: Tap any vehicle or the lightning bolt to inject attacks, trigger the AI Detector, and inspect SHAP explanations.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Search Box
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (val) => ref.read(vehiclesSearchQueryProvider.notifier).state = val,
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search by Vehicle ID or Status...',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppTheme.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),

              // 🔹 Table Header
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Vehicle ID',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'Trust Score',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Status / Test Action',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),

              // 🔹 Vehicles Table Rows
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredVehicles.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
                  itemBuilder: (context, index) {
                    final v = filteredVehicles[index];
                    final isTrusted = v.trustStatus.toLowerCase() == 'trusted';
                    final isSuspicious = v.trustStatus.toLowerCase() == 'suspicious';
                    final statusColor = isTrusted ? AppTheme.safe : (isSuspicious ? AppTheme.warning : AppTheme.error);

                    return InkWell(
                      onTap: () => _showVehicleActionSheet(context, ref, v.id, v.trustScore, v.attackType),
                      child: Container(
                        color: AppTheme.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                        child: Row(
                          children: [
                            // Vehicle ID & Type Badge
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Icon(
                                    v.isEmergency ? Icons.local_hospital_rounded : Icons.directions_car_rounded,
                                    color: v.isEmergency ? const Color(0xFFE45D3F) : AppTheme.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    v.id,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Trust Score Bar & Number
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${v.trustScore.toInt()}%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Status Pill Badge & Test Button
                            Expanded(
                              flex: 4,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      v.trustStatus,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Quick Attack Test Button
                                  IconButton(
                                    icon: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFE45D3F)),
                                    tooltip: 'Inject Test Attack',
                                    onPressed: () => _showInjectAttackSheet(context, ref, v.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Modal: Choose between Injecting Attack or Viewing SHAP Explanation
  void _showVehicleActionSheet(BuildContext context, WidgetRef ref, String vehicleId, double score, String attackType) {
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Node $vehicleId',
                          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Trust: ${score.toInt()}% • Last Flag: $attackType',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bolt_rounded, color: Color(0xFFE45D3F)),
                  title: Text('Inject Test Attack', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text('Simulate speed, GPS, or fake emergency misbehavior to test the AI', style: GoogleFonts.outfit(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInjectAttackSheet(context, ref, vehicleId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1)),
                  title: Text('View Explainable AI (SHAP)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text('Inspect feature attribution and reasoning from the ML classifier', style: GoogleFonts.outfit(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/vehicles/$vehicleId/explanation');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: AppTheme.safe),
                  title: Text('Reset Trust to 95%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text('Restore vehicle to normal certified behavior', style: GoogleFonts.outfit(fontSize: 12)),
                  onTap: () {
                    ref.read(dashboardProvider.notifier).resetVehicleTrust(vehicleId);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vehicle $vehicleId trust score restored to 95%.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Modal: Inject Specific Attack Scenarios
  void _showInjectAttackSheet(BuildContext context, WidgetRef ref, String vehicleId) {
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
                  'Select Attack to Inject on $vehicleId',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'The ML Misbehavior Detector will evaluate kinematic & spatial deltas in real-time.',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                _attackOption(
                  ctx: ctx,
                  context: context,
                  ref: ref,
                  vehicleId: vehicleId,
                  title: 'Speed Anomaly (Kinematic Attack)',
                  subtitle: 'Transmits velocity at 142 km/h with sudden 7.8 m/s² acceleration spike',
                  icon: Icons.speed_rounded,
                  attackType: 'Speed Anomaly',
                ),
                _attackOption(
                  ctx: ctx,
                  context: context,
                  ref: ref,
                  vehicleId: vehicleId,
                  title: 'GPS Position Spoofing',
                  subtitle: 'Injects conflicting coordinates outside RSU radio communication range',
                  icon: Icons.pin_drop_rounded,
                  attackType: 'Position Spoofing',
                ),
                _attackOption(
                  ctx: ctx,
                  context: context,
                  ref: ref,
                  vehicleId: vehicleId,
                  title: 'Fake Emergency Claim',
                  subtitle: 'Claims priority preemption siren without certified cryptographic signature',
                  icon: Icons.emergency_rounded,
                  attackType: 'Fake Emergency Claim',
                ),
                _attackOption(
                  ctx: ctx,
                  context: context,
                  ref: ref,
                  vehicleId: vehicleId,
                  title: 'Sybil Identity Attack',
                  subtitle: 'Rapidly broadcasts multiple fake sender IDs from one transmitter',
                  icon: Icons.group_work_rounded,
                  attackType: 'Sybil Identity Attack',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attackOption({
    required BuildContext ctx,
    required BuildContext context,
    required WidgetRef ref,
    required String vehicleId,
    required String title,
    required String subtitle,
    required IconData icon,
    required String attackType,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE45D3F).withValues(alpha: 0.12),
        child: Icon(icon, color: const Color(0xFFE45D3F), size: 18),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textSecondary)),
      onTap: () {
        Navigator.pop(ctx);
        ref.read(dashboardProvider.notifier).injectAttackOnVehicle(
              vehicleId: vehicleId,
              attackType: attackType,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            content: Text('$attackType injected on $vehicleId! Trust penalized.'),
            action: SnackBarAction(
              label: 'VIEW SHAP',
              textColor: const Color(0xFFE45D3F),
              onPressed: () {
                context.push('/vehicles/$vehicleId/explanation');
              },
            ),
          ),
        );
      },
    );
  }

  // 🔹 Dialog: Add New Vehicle Node
  void _showAddVehicleDialog(BuildContext context, WidgetRef ref) {
    final idController = TextEditingController(text: 'V-${(100 + (DateTime.now().millisecondsSinceEpoch % 800))}');
    bool isEmergency = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Deploy New Vehicle Node', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register a new connected vehicle into the live VANET mesh.', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle ID',
                      labelStyle: GoogleFonts.outfit(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Emergency Vehicle (Ambulance)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: isEmergency,
                    activeColor: const Color(0xFFE45D3F),
                    onChanged: (val) {
                      setDialogState(() => isEmergency = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final id = idController.text.trim();
                    if (id.isNotEmpty) {
                      ref.read(dashboardProvider.notifier).addTestVehicle(
                            id: id,
                            initialTrust: 95.0,
                            isEmergency: isEmergency,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vehicle $id deployed to network!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: Text('Deploy Node', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
