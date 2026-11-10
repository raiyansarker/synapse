import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../models/user_state.dart';

// =============================================================================
// SETTINGS PAGE (Minimalist & Compact)
// =============================================================================
class ProfilePage extends StatefulWidget {
  final bool embedded;
  const ProfilePage({super.key, this.embedded = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _soundEnabled = true;

  ImageProvider _avatarProvider(UserState u) =>
      u.avatarPath != null && File(u.avatarPath!).existsSync()
          ? FileImage(File(u.avatarPath!))
          : const NetworkImage(kDefaultAvatar) as ImageProvider;

  Future<void> _pickAvatar([ImageSource source = ImageSource.gallery]) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      userNotifier.value = userNotifier.value.copyWith(avatarPath: picked.path);
    }
  }

  Future<void> _showAvatarPickerOptions() async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0F172A)),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0F172A)),
                title: const Text('Take Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              if (userNotifier.value.avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  title: const Text('Remove Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(ctx);
                    userNotifier.value = userNotifier.value.copyWith(avatarPath: null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: userNotifier.value.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profile Name',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: kWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty && result != userNotifier.value.name) {
      userNotifier.value = userNotifier.value.copyWith(name: result);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final auth = await authenticateBiometrics(context);
      if (auth) {
        userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: true);
      }
    } else {
      userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: false);
    }
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out from Synapse?',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              shellTabIndex.value = 0;
              authNotifier.value = false;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: kWhite,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + (widget.embedded ? 90 : 20);

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ValueListenableBuilder<UserState>(
        valueListenable: userNotifier,
        builder: (context, user, _) => ListView(
          padding: EdgeInsets.fromLTRB(20, 2, 20, bottomInset),
          children: [
            // Top Profile Avatar & Name (Centered, prominent avatar)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPickerOptions,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: _avatarProvider(user),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(color: kWhite, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 15,
                                color: kWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.name.isEmpty ? kHardcodedName : user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Top Group (No header label)
            _buildRow(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: _editName,
            ),
            const _MinimalDivider(),
            _buildRow(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synapse Privacy Policy: Data is securely encrypted on-device.')),
                );
              },
            ),
            const _MinimalDivider(),
            _buildSwitchRow(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Security',
              value: user.isBiometricEnabled,
              onChanged: _toggleBiometrics,
            ),

            // Section 2: Preferences
            const _SectionHeader('Preferences'),
            _buildRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => shellTabIndex.value = 3,
            ),
            const _MinimalDivider(),
            _buildRow(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme: Strict Monochrome Light Mode active')),
                );
              },
            ),
            const _MinimalDivider(),
            _buildSwitchRow(
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),

            // Section 3: Contacts & Account
            const _SectionHeader('Contacts'),
            _buildRow(
              icon: Icons.help_outline_rounded,
              title: 'Contacts Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact support at support@synapse.app')),
                );
              },
            ),
            const _MinimalDivider(),
            _buildRow(
              icon: Icons.receipt_long_outlined,
              title: 'Transactions',
              onTap: () => shellTabIndex.value = 1,
            ),
            const _MinimalDivider(),
            _buildRow(
              icon: Icons.favorite_border_rounded,
              title: 'Favorites',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favorites list is empty.')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Sign Out Button (Exact style from reference)
            Center(
              child: GestureDetector(
                onTap: _confirmLogout,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.5),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF0F172A),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: const Color(0xFF0F172A),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

// =============================================================================
// MINIMAL HAIRLINE DIVIDER
// =============================================================================
class _MinimalDivider extends StatelessWidget {
  const _MinimalDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFF1F5F9),
      indent: 34,
      endIndent: 0,
    );
  }
}
