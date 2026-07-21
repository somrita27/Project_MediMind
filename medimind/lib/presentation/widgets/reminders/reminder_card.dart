import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/schedule_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback? onTapStatus;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTapStatus,
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
    final isTaken = reminder.status == 'Taken';
    final isMissed = reminder.status == 'Missed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTaken
              ? AppColors.success.withOpacity(0.4)
              : AppColors.cardBorder,
        ),
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
                  style: AppTextStyles.titleMedium.copyWith(
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                    color: isTaken
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.instruction,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTapStatus,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTaken
                        ? AppColors.success
                        : (isMissed
                            ? AppColors.error.withOpacity(0.12)
                            : Colors.transparent),
                    border: Border.all(
                      color: isTaken
                          ? AppColors.success
                          : (isMissed ? AppColors.error : AppColors.cardBorder),
                      width: 1.6,
                    ),
                  ),
                  child: Icon(
                    isTaken ? Icons.check : (isMissed ? Icons.close : null),
                    size: 18,
                    color: isTaken
                        ? Colors.white
                        : (isMissed ? AppColors.error : null),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
