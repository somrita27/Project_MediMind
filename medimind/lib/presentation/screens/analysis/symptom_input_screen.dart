import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/health_service.dart';
import '../../widgets/common/gradient_button.dart';

class SymptomInputScreen extends StatefulWidget {
  final String? initialSource; // 'camera' | 'gallery' | null

  const SymptomInputScreen({super.key, this.initialSource});

  @override
  State<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends State<SymptomInputScreen> {
  final _symptomCtrl = TextEditingController();
  File? _pickedImage;
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialSource == 'camera') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(fromCamera: true));
    } else if (widget.initialSource == 'gallery') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(fromCamera: false));
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
          content: Text('Please describe your symptoms or upload a photo'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await AuthService().getCurrentUserModel();
      if (user == null) throw Exception('Not signed in');

      final session = await HealthService().analyzeAndSave(
        userId: user.uid,
        symptoms: text.isEmpty ? 'Photo uploaded — please analyze the image' : text,
        imageFile: _pickedImage,
        allergies: user.allergies,
      );

      if (mounted) {
        context.go(AppRoutes.analysisResult, extra: session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _symptomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check Symptoms'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Describe your symptoms', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),

              // Symptom text input
              TextFormField(
                controller: _symptomCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type your symptoms here...',
                  alignLabelWithHint: true,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 60),
                    child: Icon(
                      Icons.mic_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
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
              const SizedBox(height: 24),

              const Text('Upload a photo (optional)', style: AppTextStyles.titleLarge),
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
                    child: _PhotoPickerButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () => _pickImage(fromCamera: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoPickerButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () => _pickImage(fromCamera: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              GradientButton(
                text: 'Analyze Symptoms',
                onPressed: _analyze,
                isLoading: _loading,
                icon: _loading
                    ? null
                    : const Icon(Icons.search_rounded, color: Colors.white, size: 20),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI suggestions are not a substitute for professional medical advice.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            height: 200,
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
}

class _PhotoPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoPickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
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