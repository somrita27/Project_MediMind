import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

Future<void> _openEditProfile() async {
  if (_user == null) return;

  final updated = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => EditProfileScreen(user: _user!),
    ),
  );

  if (updated == true) {
    await _loadUser();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) context.go(AppRoutes.login);
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [

              /// Green Header
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppGradients.card,
                ),
              ),

              /// White Curved Body
              Positioned(
                top: 170,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(38),
                      topRight: Radius.circular(38),
                    ),
                  ),
                ),
              ),

              /// Scroll Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [

                      const SizedBox(height: 105),
                      _buildHeader(),

                      const SizedBox(height: 28),
                      _buildMenuItems(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}

  Widget _buildHeader() {
  return Column(
    children: [

      // Profile Avatar
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [

          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage:
                    (_user?.photoUrl != null &&
                            _user!.photoUrl!.isNotEmpty)
                        ? NetworkImage(_user!.photoUrl!)
                        : null,
                child: (_user?.photoUrl == null ||
                        _user!.photoUrl!.isEmpty)
                    ? Text(
                        _user?.fullName.isNotEmpty == true
                            ? _user!.fullName[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          Positioned(
            bottom: 2,
            right: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  // Upload profile image later
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 22),

      Text(
        _user?.fullName ?? "User",
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      const SizedBox(height: 6),

      Text(
        _user?.email ?? "",
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSection([
            _ProfileTile(
              icon: Icons.person_outline,
              label: 'Personal Information',
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: _openEditProfile,
            ),
            _ProfileTile(
              icon: Icons.warning_amber_outlined,
              label: 'Allergies',
              trailing: Text(
                _user?.allergies.isNotEmpty == true
                    ? _user!.allergies.join(', ')
                    : 'None',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
            _ProfileTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _showChangePassword(),
            ),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              label: 'Notification Settings',
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
            _ProfileTile(
              icon: Icons.info_outline,
              label: 'About MediMind',
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AboutScreen(),
    ),
  );
},
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
            _ProfileTile(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: _signOut,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> tiles) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(
        color: AppColors.cardBorder.withOpacity(.5),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: tiles
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: [
                  entry.value,
                  if (entry.key != tiles.length - 1)
                    const Divider(
                      indent: 58,
                      endIndent: 18,
                      height: 1,
                    ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );
}

  Future<void> _showChangePassword() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (ctrl.text.length >= 6) {
                await _authService.changePassword(ctrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Row(
            children: [

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),

              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}