import 'package:beltei_app/controllers/auth_controller.dart';
import 'package:beltei_app/controllers/profile_controller.dart';
import 'package:beltei_app/controllers/theme_controller.dart';
import 'package:beltei_app/core/config/app_config.dart';
import 'package:beltei_app/core/theme/app_colors.dart';
import 'package:beltei_app/data/models/app_user.dart';
import 'package:beltei_app/screens/dashboard_screen.dart';
import 'package:beltei_app/screens/login_screen.dart';
import 'package:beltei_app/screens/my_claims_screen.dart';
import 'package:beltei_app/screens/my_items_screen.dart';
import 'package:beltei_app/screens/report_item_screen.dart';
import 'package:beltei_app/screens/settings_screen.dart';
import 'package:beltei_app/widgets/app_logo.dart';
import 'package:beltei_app/widgets/primary_button.dart';
import 'package:beltei_app/widgets/profile_activity_list.dart';
import 'package:beltei_app/widgets/profile_stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _imageUrl = TextEditingController();
  String? _pendingAvatarUrl;
  bool _editing = false;
  bool _showPasswordForm = false;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  ProfileController get _profileCtrl => Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Get.find<AuthController>();
      if (!auth.isLoggedIn) return;
      await auth.refreshSessionUser();
      await _profileCtrl.load(force: true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    _imageUrl.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _syncFields(AppUser user) {
    final name = user.name ?? '';
    final studentId = user.studentId ?? '';
    final image = user.image ?? '';
    if (_name.text != name) _name.text = name;
    if (_studentId.text != studentId) _studentId.text = studentId;
    if (_imageUrl.text != image) _imageUrl.text = image;
  }

  String get _avatarUrl {
    final pending = _pendingAvatarUrl;
    if (pending != null && pending.isNotEmpty) return pending;
    final typed = _imageUrl.text.trim();
    if (typed.isNotEmpty) return typed;
    final profileImage = _profileCtrl.profile.value?.image;
    if (profileImage != null && profileImage.isNotEmpty) return profileImage;
    final authImage = Get.find<AuthController>().user.value?.image;
    if (authImage != null && authImage.isNotEmpty) return authImage;
    return '';
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return 'Not set';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final url = await _profileCtrl.uploadAvatarFile(file);
    if (!mounted || url == null) return;
    setState(() {
      _pendingAvatarUrl = url;
      _imageUrl.text = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo uploaded — tap Save profile to apply')),
    );
  }

  Future<void> _saveProfile() async {
    final ok = await _profileCtrl.saveProfile(
      name: _name.text,
      studentId: _studentId.text,
      imageUrl: _imageUrl.text,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _editing = false;
        _pendingAvatarUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else if (_profileCtrl.error.value.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_profileCtrl.error.value)),
      );
    }
  }

  Future<void> _changePassword() async {
    final ok = await _profileCtrl.changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirmPassword.text,
    );
    if (!mounted) return;
    if (ok) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      setState(() => _showPasswordForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } else if (_profileCtrl.error.value.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_profileCtrl.error.value)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      if (!auth.isLoggedIn) {
        return _GuestProfile(onLogin: () => Get.to(() => const LoginScreen()));
      }

      if (_profileCtrl.isLoading.value && _profileCtrl.profile.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final user = _profileCtrl.profile.value ?? auth.user.value;
      if (user == null) {
        return const Center(child: Text('Could not load profile'));
      }

      if (!_editing) _syncFields(user);

      return RefreshIndicator(
        onRefresh: () async {
          await auth.refreshSessionUser();
          await _profileCtrl.load(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(url: _avatarUrl, user: user, onTap: _editing ? _pickAvatar : null),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                      if (user.email?.isNotEmpty == true &&
                          user.displayName != user.email?.trim())
                        Text(user.email!, style: Theme.of(context).textTheme.bodySmall),
                      if (user.phoneNumber?.isNotEmpty == true &&
                          user.displayName != user.phoneNumber?.trim())
                        Text(user.phoneNumber!, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      _RoleChip(label: user.roleLabel),
                      if (user.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Member since ${DateFormat.yMMMd().format(user.createdAt!.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap avatar to upload a photo (any format, auto-compressed)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (user.stats != null) ...[
              const SizedBox(height: 20),
              Text('Your activity', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              ProfileStatsGrid(
                stats: user.stats!,
                onLostTap: () => Get.to(() => const MyItemsScreen(initialType: 'LOST')),
                onFoundTap: () => Get.to(() => const MyItemsScreen(initialType: 'FOUND')),
                onClaimsTap: () => Get.to(() => const MyClaimsScreen()),
                onResolvedTap: () => Get.to(
                  () => const MyItemsScreen(initialStatus: 'RESOLVED'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Recent activity', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ProfileActivityList(activities: user.recentActivity),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Account', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _editing = !_editing;
                    if (!_editing) _pendingAvatarUrl = null;
                  }),
                  child: Text(_editing ? 'Cancel' : 'Edit'),
                ),
              ],
            ),
            if (_editing) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentId,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (optional)',
                  hintText: 'Or upload via avatar above',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Obx(
                () => PrimaryButton(
                  label: 'Save profile',
                  loading: _profileCtrl.isSaving.value,
                  onPressed: _saveProfile,
                ),
              ),
            ],
            if (!_editing) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile information',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Full name',
                        value: _displayValue(user.name),
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _displayValue(user.email),
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: _displayValue(user.phoneNumber),
                      ),
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Student ID',
                        value: _displayValue(user.studentId),
                      ),
                      _InfoTile(
                        icon: Icons.shield_outlined,
                        label: 'Role',
                        value: user.roleLabel,
                      ),
                      _InfoTile(
                        icon: Icons.verified_outlined,
                        label: 'Email verified',
                        value: user.emailVerified ? 'Yes' : 'No',
                      ),
                      _InfoTile(
                        icon: Icons.lock_outline,
                        label: 'Password login',
                        value: user.hasPassword ? 'Enabled' : 'Not set',
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: _formatDate(user.createdAt),
                      ),
                      _InfoTile(
                        icon: Icons.login_outlined,
                        label: 'Last sign-in',
                        value: _formatDate(user.lastSignInAt),
                      ),
                      _InfoTile(
                        icon: Icons.fingerprint_outlined,
                        label: 'User ID',
                        value: user.id,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Security', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (!user.hasPassword)
              Text(
                'Google-only accounts cannot change password here.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (!_showPasswordForm)
              TextButton(
                onPressed: () => setState(() => _showPasswordForm = true),
                child: const Text('Change password'),
              )
            else ...[
              TextField(
                controller: _currentPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => PrimaryButton(
                        label: 'Update password',
                        loading: _profileCtrl.isSaving.value,
                        onPressed: _changePassword,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _showPasswordForm = false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Quick links', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Get.to(() => const DashboardScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('My items'),
              onTap: () => Get.to(() => const MyItemsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('My claims'),
              onTap: () => Get.to(() => const MyClaimsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Get.to(() => const SettingsScreen()),
            ),
            if (user.role == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin panel (web)'),
                subtitle: Text('${AppConfig.apiBaseUrl}/admin/dashboard'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Open ${AppConfig.apiBaseUrl}/admin/dashboard in a browser',
                      ),
                    ),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Report lost item'),
              onTap: () => Get.to(() => const ReportItemScreen(initialType: 'LOST')),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Report found item'),
              onTap: () => Get.to(() => const ReportItemScreen(initialType: 'FOUND')),
            ),
            const Divider(),
            Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Obx(() {
              final mode = theme.mode.value;
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => theme.setMode(s.first),
              );
            }),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final name = user.displayName;
                await auth.logout();
                _profileCtrl.profile.value = null;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Signed out — $name')),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      );
    });
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppLogo(size: 72),
        const SizedBox(height: 16),
        Text(AppConfig.appName, style: Theme.of(context).textTheme.titleLarge),
        Text(AppConfig.universityLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
            title: const Text('Sign in'),
            subtitle: const Text('Post items, submit claims, and manage your profile'),
            onTap: onLogin,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.user,
    this.onTap,
  });

  final String url;
  final AppUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.surfaceMutedLight,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
