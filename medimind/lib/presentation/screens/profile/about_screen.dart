import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: CustomScrollView(
        slivers: [

          // ===========================
          // APP BAR
          // ===========================

          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,

            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: null,

              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                ),

                child: SafeArea(
                  child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    const SizedBox(height: 55),

    Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: ClipOval(
      child: Image.asset(
        "assets/icons/app_logo_medimind.png",
        fit: BoxFit.contain,
      ),
    ),
  ),
),

    const SizedBox(height: 18),

    Text(
      "MediMind",
      style: AppTextStyles.displayMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 8),

    Text(
      "Your Smart Health Companion",
      style: AppTextStyles.bodyMedium.copyWith(
        color: Colors.white.withOpacity(.9),
      ),
    ),

    const SizedBox(height: 20),
  ],
),
                ),
              ),
            ),
          ),

          // ===========================
          // BODY
          // ===========================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [

                  _buildCard(
                    icon: Icons.info_outline,
                    title: "About",

                    child: Text(
                      "MediMind is an AI-powered healthcare assistant designed to help users monitor their health, predict possible diseases, manage medications, and maintain a healthier lifestyle through smart and accessible digital healthcare tools.",
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildCard(
                    icon: Icons.health_and_safety_outlined,
                    title: "Features",

                    child: const Column(
                      children: [

                        _FeatureTile(
                          icon: Icons.psychology_alt,
                          title: "AI Disease Prediction",
                        ),

                        _FeatureTile(
                          icon: Icons.medication_outlined,
                          title: "Medicine Reminder",
                        ),

                        _FeatureTile(
                          icon: Icons.history,
                          title: "Medical History",
                        ),

                        _FeatureTile(
                          icon: Icons.analytics_outlined,
                          title: "Health Reports",
                        ),

                        _FeatureTile(
                          icon: Icons.lock_outline,
                          title: "Secure Authentication",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildCard(
                    icon: Icons.groups_outlined,
                    title: "Developed By",

                    child: const Column(
                      children: [

                        _DeveloperTile(
                          name: "Srijon Ghosh",
                        ),

                        _DeveloperTile(
                          name: "Somrita Bala",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "© 2026 MediMind",
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Version 1.0.0",
                    style: AppTextStyles.labelSmall,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
    Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 14),

                Text(
                  title,
                  style: AppTextStyles.headlineMedium,
                ),

              ],
            ),

            const SizedBox(height: 20),

            child,
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureTile({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge,
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _DeveloperTile extends StatelessWidget {
  final String name;

  const _DeveloperTile({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [

          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(.12),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              name,
              style: AppTextStyles.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
