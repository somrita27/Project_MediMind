import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/health_session_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/health_service.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/gradient_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _authService = AuthService();
  final _healthService = HealthService();
  final _symptomCtrl = TextEditingController();
  final _picker = ImagePicker();

  UserModel? _user;
  List<HealthSession> _recentSessions = [];
  bool _loading = true;

  File? _pickedImage;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _symptomCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUserModel();

      if (user != null) {
        final sessions = await _healthService.getUserSessions(user.uid);

        if (mounted) {
          setState(() {
            _user = user;
            _recentSessions = sessions.take(3).toList();
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final xFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (xFile != null && mounted) {
      setState(() => _pickedImage = File(xFile.path));
    }
  }

  Future<void> _analyze() async {
    final text = _symptomCtrl.text.trim();
    if (text.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe your symptoms or add a photo first'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _analyzing = true);
    try {
      final user = _user ?? await _authService.getCurrentUserModel();
      if (user == null) throw Exception('Not signed in');

      final session = await _healthService.analyzeAndSave(
        userId: user.uid,
        symptoms:
            text.isEmpty ? 'Photo uploaded — please analyze the image' : text,
        imageFile: _pickedImage,
        allergies: user.allergies,
      );

      if (mounted) {
        // Clear the inline search once handed off to the result screen.
        _symptomCtrl.clear();
        setState(() => _pickedImage = null);
        context.push(AppRoutes.analysisResult, extra: session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSymptomSearchCard(),
                      const SizedBox(height: 28),
                      _buildRecentHistory(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_user?.fullName.split(' ').first ?? 'there'} 👋',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'How are you feeling today?',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  /// A live, inline symptom search — no more bouncing to a near-identical
  /// second screen just to type. Typing, photo upload, and analyzing all
  /// happen right here.
  Widget _buildSymptomSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe your symptoms', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),

          // A real, working search field — typing happens right on Home.
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _symptomCtrl.text.isNotEmpty
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.cardBorder,
              ),
            ),
            child: TextField(
              controller: _symptomCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _analyze(),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. sore throat, mild fever since yesterday...',
                hintStyle:
                    const TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 22),
                suffixIcon: _symptomCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textHint),
                        onPressed: () => setState(() => _symptomCtrl.clear()),
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.cardBorder)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: AppTextStyles.bodyMedium),
              ),
              Expanded(child: Divider(color: AppColors.cardBorder)),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Upload a photo (optional)',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload image of rash, wound, eye condition etc.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),

          if (_pickedImage != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 14),
          ],

          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () => _pickImage(fromCamera: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _pickImage(fromCamera: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GradientButton(
            text: 'Analyze Symptoms',
            onPressed: _analyzing ? null : _analyze,
            isLoading: _analyzing,
            icon: _analyzing
                ? null
                : const Icon(Icons.search_rounded,
                    color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            _pickedImage!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _pickedImage = null),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent History', style: AppTextStyles.titleLarge),
            GestureDetector(
              // push (not go) so the History tab can be reopened
              // as many times as needed, with proper back navigation.
              onTap: () => context.push(AppRoutes.history),
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_recentSessions.isEmpty)
          _buildEmptyHistory()
        else
          ..._recentSessions.map(
            (s) => _HistorySessionTile(
              session: s,
              onTap: () => context.push(AppRoutes.historyDetail, extra: s),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
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
          Icon(Icons.history_rounded, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('No history yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Your past analyses will appear here',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySessionTile extends StatelessWidget {
  final HealthSession session;
  final VoidCallback onTap;

  const _HistorySessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medical_information_outlined,
                  size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.result.likelyCondition,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM yyyy').format(session.createdAt),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                session.status,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
