import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/health_service.dart';
import '../../../data/services/notification_service.dart';

/// Full-screen "alarm style" reminder shown when a medicine's scheduled
/// time arrives — mirrors a classic alarm-clock ring screen instead of a
/// small notification banner, so it's hard to miss.
class MedicineAlarmScreen extends StatefulWidget {
  final String reminderId;
  final String medicineName;
  final String dosage;
  final String instruction;
  final String time;

  const MedicineAlarmScreen({
    super.key,
    required this.reminderId,
    required this.medicineName,
    required this.dosage,
    required this.instruction,
    required this.time,
  });

  @override
  State<MedicineAlarmScreen> createState() => _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState extends State<MedicineAlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _busy = false;

  static const _bgDark = Color(0xFF0E1F1A);
  static const _cardDark = Color(0xFF16332B);
  static const _accent = Color(0xFF2BAE7E);

  @override
  void initState() {
    super.initState();
    HapticFeedback.vibrate();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _markTaken() async {
    if (widget.reminderId.isEmpty) {
      if (mounted) context.go(AppRoutes.reminders);
      return;
    }
    setState(() => _busy = true);
    try {
      await HealthService().updateReminderStatus(widget.reminderId, 'Taken');
    } finally {
      if (mounted) context.go(AppRoutes.reminders);
    }
  }

  Future<void> _snooze() async {
    setState(() => _busy = true);
    try {
      await NotificationService().scheduleOneOffReminder(
        reminderId: widget.reminderId,
        medicineName: widget.medicineName,
        dosage: widget.dosage,
        instruction: widget.instruction,
        time: widget.time,
        after: const Duration(minutes: 10),
      );
    } finally {
      if (mounted) context.go(AppRoutes.reminders);
    }
  }

  void _dismiss() {
    context.go(AppRoutes.reminders);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bgDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.12);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Time to take your medicine!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: _accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.medicineName}${widget.dosage.isNotEmpty ? ' ${widget.dosage}' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.instruction.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.instruction,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.time.isNotEmpty)
                        Text(
                          widget.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _markTaken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Mark as Taken',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _snooze,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Snooze 10 mins',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _busy ? null : _dismiss,
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
