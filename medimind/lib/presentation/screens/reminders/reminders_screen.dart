import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/health_service.dart';
import '../../widgets/reminders/reminder_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _healthService = HealthService();
  List<ReminderModel> _reminders = [];
  List<MedicineSchedule> _schedules = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService().getCurrentUserModel();
    if (user == null) return;

    final reminders = await _healthService.getTodayReminders(user.uid);
    final schedules = await _healthService.getUserSchedules(user.uid);
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _schedules = schedules;
        _loading = false;
      });
    }
  }

  Future<void> _markTaken(ReminderModel reminder) async {
    await _healthService.updateReminderStatus(reminder.id, 'Taken');
    setState(() {
      final idx = _reminders.indexWhere((r) => r.id == reminder.id);
      if (idx >= 0) _reminders[idx] = reminder.copyWith(status: 'Taken');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as taken ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendarStrip(),
                      const SizedBox(height: 24),
                      _buildTodayReminders(),
                      if (_schedules.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildActiveSchedules(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 3 - i)));

    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: AppTextStyles.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTodayReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Reminders", style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        if (_reminders.isEmpty)
          _buildEmpty('No reminders for today', 'Set a schedule to see reminders here')
        else
          ..._reminders.map(
            (r) => ReminderCard(
              reminder: r,
              onMarkTaken: () => _markTaken(r),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveSchedules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Active Schedules', style: AppTextStyles.titleLarge),
            Text(
              '${_schedules.length} active',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._schedules.map((s) => _ScheduleTile(schedule: s)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          child: const Text('View All Schedules'),
        ),
      ],
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final MedicineSchedule schedule;

  const _ScheduleTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final remaining = schedule.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${schedule.medicineName} ${schedule.dosage}',
                  style: AppTextStyles.titleMedium,
                ),
                Text(
                  schedule.timings.join(' · '),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '$remaining days left',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}