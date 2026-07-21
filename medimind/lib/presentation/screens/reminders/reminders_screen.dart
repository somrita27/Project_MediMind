import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String? _userId;

  // The Monday that starts the currently displayed week.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _loadInitial();
  }

  DateTime _mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadInitial() async {
    final user = await AuthService().getCurrentUserModel();
    if (user == null) return;
    _userId = user.uid;

    final schedules = await _healthService.getUserSchedules(user.uid);
    final reminders =
        await _healthService.getRemindersForDate(user.uid, _selectedDate);

    if (mounted) {
      setState(() {
        _schedules = schedules;
        _reminders = reminders;
        _loading = false;
      });
    }
  }

  Future<void> _selectDate(DateTime date) async {
    if (_userId == null) return;
    setState(() {
      _selectedDate = date;
      _loading = true;
    });
    final reminders = await _healthService.getRemindersForDate(_userId!, date);
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
    }
  }

  Future<void> _refreshCurrentDay() async {
    if (_userId == null) return;
    final schedules = await _healthService.getUserSchedules(_userId!);
    final reminders =
        await _healthService.getRemindersForDate(_userId!, _selectedDate);
    if (mounted) {
      setState(() {
        _schedules = schedules;
        _reminders = reminders;
      });
    }
  }

  void _previousWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  /// Cycles a reminder's status: Upcoming -> Taken -> Missed -> Upcoming.
  Future<void> _cycleStatus(ReminderModel reminder) async {
    final next = switch (reminder.status) {
      'Upcoming' => 'Taken',
      'Taken' => 'Missed',
      _ => 'Upcoming',
    };
    await _healthService.updateReminderStatus(reminder.id, next);
    setState(() {
      final idx = _reminders.indexWhere((r) => r.id == reminder.id);
      if (idx >= 0) _reminders[idx] = reminder.copyWith(status: next);
    });
    if (mounted) {
      final label = next == 'Taken'
          ? 'Marked as taken ✓'
          : next == 'Missed'
              ? 'Marked as not taken'
              : 'Marked as yet to take';
      final color = next == 'Taken'
          ? AppColors.success
          : next == 'Missed'
              ? AppColors.error
              : AppColors.warning;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
        child: RefreshIndicator(
          onRefresh: _refreshCurrentDay,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 14),
                _buildWeekStrip(),
                const SizedBox(height: 24),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildDayReminders(),
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

  Widget _buildMonthHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_weekStart),
            style: AppTextStyles.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          onPressed: _previousWeek,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onPressed: _nextWeek,
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return Row(
      children: days.map((day) {
        final isSelected = _isSameDay(day, _selectedDate);
        final isToday = _isSameDay(day, today);

        return Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected
                    ? null
                    : (isToday
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? AppColors.primary
                              : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayReminders() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final title = isToday
        ? "Today's Reminders"
        : DateFormat('EEEE, d MMM').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        if (_reminders.isEmpty)
          _buildEmpty(
            'No reminders for this day',
            'Set a schedule to see reminders here',
          )
        else
          ..._reminders.map(
            (r) => ReminderCard(
              reminder: r,
              onTapStatus: () => _cycleStatus(r),
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
            remaining >= 0 ? '$remaining days left' : 'Ended',
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
