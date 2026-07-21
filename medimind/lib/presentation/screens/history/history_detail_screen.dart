import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_session_model.dart';
import '../../widgets/common/medicine_card.dart';

class HistoryDetailScreen extends StatelessWidget {
  final HealthSession session;

  const HistoryDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final result = session.result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('History Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Symptoms', session.symptoms),
              const SizedBox(height: 16),
              _buildInfoRow('Condition', result.likelyCondition,
                  valueColor: AppColors.primary),
              const SizedBox(height: 20),

              // Medicines
              const Text('Medicines', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              ...result.medicines.map((m) => MedicineCard(medicine: m)),

              const SizedBox(height: 20),

              // Advice
              const Text('General Advice', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: result.generalAdvice
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors.primary, fontSize: 16)),
                              Expanded(
                                  child:
                                      Text(a, style: AppTextStyles.bodyLarge)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Meta info
              _buildMetaRow(
                'Date',
                DateFormat('d MMM yyyy, hh:mm a').format(session.createdAt),
              ),
              const SizedBox(height: 12),
              _buildMetaRow('Status', session.status,
                  valueColor: AppColors.success),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: valueColor,
              fontWeight:
                  valueColor != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textSecondary,
            fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
            'This will permanently remove this health session from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: Implement delete from Firestore
      context.go(AppRoutes.history);
    }
  }
}
