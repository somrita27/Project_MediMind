import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_session_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/health_service.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/common/gradient_button.dart';

class SetScheduleScreen extends StatefulWidget {
  final HealthSession session;

  const SetScheduleScreen({super.key, required this.session});

  @override
  State<SetScheduleScreen> createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  // Selected medicine index
  int _selectedMedicineIndex = 0;

  // Timing selections
  final Map<String, bool> _timingSelected = {
    'Morning': false,
    'Afternoon': false,
    'Night': false,
  };

  final Map<String, TextEditingController> _timingControllers = {
    'Morning': TextEditingController(text: '08:00 AM'),
    'Afternoon': TextEditingController(text: '02:00 PM'),
    'Night': TextEditingController(text: '08:00 PM'),
  };

  int _durationDays = 3;
  bool _saving = false;

  List<MedicineModel> get _medicines => widget.session.result.medicines;

  MedicineModel get _selectedMedicine => _medicines[_selectedMedicineIndex];

  List<String> get _selectedTimings =>
      _timingSelected.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

  @override
  void dispose() {
    for (final c in _timingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(String timing) async {
    final parts = _timingControllers[timing]!.text.split(RegExp(r'[: ]'));
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (_timingControllers[timing]!.text.contains('PM') && hour != 12) hour += 12;
    if (_timingControllers[timing]!.text.contains('AM') && hour == 12) hour = 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) {
      final formatted = picked.format(context);
      setState(() => _timingControllers[timing]!.text = formatted);
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedTimings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one time slot'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = await AuthService().getCurrentUserModel();
      if (user == null) throw Exception('Not signed in');

      final timingTimes = {
        for (final t in _selectedTimings) t: _timingControllers[t]!.text
      };

      final schedule = await HealthService().saveSchedule(
        userId: user.uid,
        sessionId: widget.session.id,
        medicineName: _selectedMedicine.name,
        dosage: _selectedMedicine.dosage,
        instruction: _selectedMedicine.instruction,
        timings: _selectedTimings,
        timingTimes: timingTimes,
        durationDays: _durationDays,
      );

      // Generate reminder docs
      await HealthService().generateReminders(schedule);

      // Schedule local notifications
      await NotificationService().scheduleRemindersForSchedule(schedule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved! Reminders are set.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.reminders);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Medicine Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AppRoutes.analysisResult, extra: widget.session),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine selector (if multiple)
              if (_medicines.length > 1) ...[
                const Text('Select Medicine', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _medicines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final selected = i == _selectedMedicineIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMedicineIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            _medicines[i].name,
                            style: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Selected medicine chip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedMedicine.name} ${_selectedMedicine.dosage}',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            _selectedMedicine.instruction,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Time slots
              const Text('Select Time', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              ..._timingSelected.keys.map(
                (timing) => _TimingTile(
                  timing: timing,
                  timeText: _timingControllers[timing]!.text,
                  selected: _timingSelected[timing]!,
                  onToggle: (val) => setState(() => _timingSelected[timing] = val),
                  onEditTime: () => _pickTime(timing),
                ),
              ),

              const SizedBox(height: 24),

              // Duration
              const Text('Duration', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Text(
                        '$_durationDays',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _durationDays,
                      decoration: const InputDecoration(),
                      items: AppConstants.durationOptions
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                    '$d ${d == 1 ? 'Day' : 'Days'}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _durationDays = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Note: Set a reminder for each time',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              GradientButton(
                text: 'Save Schedule',
                onPressed: _saveSchedule,
                isLoading: _saving,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingTile extends StatelessWidget {
  final String timing;
  final String timeText;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditTime;

  const _TimingTile({
    required this.timing,
    required this.timeText,
    required this.selected,
    required this.onToggle,
    required this.onEditTime,
  });

  IconData get _icon {
    switch (timing) {
      case 'Morning':
        return Icons.wb_sunny_outlined;
      case 'Afternoon':
        return Icons.wb_sunny;
      case 'Night':
        return Icons.nightlight_round;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timing, style: AppTextStyles.titleMedium),
                  GestureDetector(
                    onTap: selected ? onEditTime : null,
                    child: Text(
                      timeText,
                      style: TextStyle(
                        color:
                            selected ? AppColors.primary : AppColors.textHint,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (v) => onToggle(v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}