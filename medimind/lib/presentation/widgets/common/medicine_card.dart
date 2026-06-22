import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_session_model.dart';

class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final bool showBorder;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.showBorder = true,
  });

  Color get _dotColor {
    switch (medicine.timeOfDay.toLowerCase()) {
      case 'morning':
        return AppColors.pillMorningIcon;
      case 'afternoon':
        return AppColors.pillAfternoonIcon;
      case 'night':
        return AppColors.pillNightIcon;
      default:
        return AppColors.primary;
    }
  }

  IconData get _timeIcon {
    switch (medicine.timeOfDay.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_sunny;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: AppColors.cardBorder)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medicine.name} ${medicine.dosage}',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  medicine.instruction,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(_timeIcon, size: 18, color: _dotColor),
        ],
      ),
    );
  }
}