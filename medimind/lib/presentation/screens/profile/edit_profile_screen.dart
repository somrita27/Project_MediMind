import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _allergyController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.user.fullName);

    _allergyController =
        TextEditingController(
          text: widget.user.allergies.join(", "),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final allergies = _allergyController.text
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updatedUser = widget.user.copyWith(
      fullName: _nameController.text.trim(),
      allergies: allergies,
    );

    await _authService.updateUserProfile(updatedUser);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Information"),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            const SizedBox(height: 10),

            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primary.withOpacity(.15),
                child: Text(
                  widget.user.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Enter your name"
                      : null,
            ),

            const SizedBox(height: 20),

            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _allergyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Allergies",
                hintText: "Example: Dust, Cold, Pollen",
                prefixIcon: Icon(Icons.health_and_safety_outlined),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}