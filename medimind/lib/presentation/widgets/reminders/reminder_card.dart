import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/schedule_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback? onMarkTaken;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onMarkTaken,
  });

  Color get _bgColor {
    switch (reminder.timing) {
      case 'Morning':
        return AppColors.pillMorning;
      case 'Afternoon':
        return AppColors.pillAfternoon;
      case 'Night':
        return AppColors.pillNight;
      default:
        return AppColors.surfaceVariant;
    }
  }

  IconData get _timeIcon {
    switch (reminder.timing) {
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

  Color get _iconColor {
    switch (reminder.timing) {
      case 'Morning':
        return AppColors.pillMorningIcon;
      case 'Afternoon':
        return AppColors.pillAfternoonIcon;
      case 'Night':
        return AppColors.pillNightIcon;
      default:
        return AppColors.primary;
    }
  }

  Color get _statusColor {
    switch (reminder.status) {
      case 'Taken':
        return AppColors.success;
      case 'Missed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_timeIcon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.medicineName,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.instruction,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reminder.time,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: reminder.status == 'Upcoming' ? onMarkTaken : null,
                child: Text(
                  reminder.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}