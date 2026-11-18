import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/avatar_image.dart';
import '../../core/state/app_state.dart';
import '../../models/user_state.dart';
import 'edit_profile_page.dart';
import 'profile_avatar_picker.dart';

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
  static const double _hPad = 20;

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  Future<void> _changePhoto(UserState user) async {
    await showProfilePhotoPickerSheet(
      context,
      hasCustomPhoto: user.avatarPath != null,
      currentAvatarPath: user.avatarPath,
      onAvatarPathChanged: (path) {
        userNotifier.value = userNotifier.value.copyWith(avatarPath: path);
      },
    );
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
          'Profile',
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
        builder: (context, user, _) {
          final displayName = user.name.isEmpty ? kHardcodedName : user.name;
          return ListView(
            padding: EdgeInsets.only(bottom: bottomInset),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 2, _hPad, 0),
                child: Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _changePhoto(user),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              key: ValueKey(user.avatarPath),
                              radius: 46,
                              backgroundColor: const Color(0xFFF1F5F9),
                              backgroundImage: userAvatarProvider(user.avatarPath),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kWhite, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: kWhite),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.virtualAddress,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRow(
                icon: Icons.add_a_photo_outlined,
                title: 'Profile Photo',
                subtitle: 'Choose, crop, or remove',
                onTap: () => _changePhoto(user),
              ),
              const _MinimalDivider(),
              _buildRow(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, email, phone',
                onTap: _openEditProfile,
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
              const _SectionHeader('Preferences'),
              _buildRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => shellTabIndex.value = 3,
              ),
              const _SectionHeader('Support'),
              _buildRow(
                icon: Icons.help_outline_rounded,
                title: 'Contact Support',
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Center(
                  child: TextButton(
                    onPressed: _confirmLogout,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                    child: const Text(
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
          );
        },
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 10.5, _hPad, 10.5),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0F172A)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 19, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  static const double _hPad = _ProfilePageState._hPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 4),
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

class _MinimalDivider extends StatelessWidget {
  const _MinimalDivider();

  /// Aligns with row content: `_hPad` + icon (20) + gap (14).
  static const double _indent = _ProfilePageState._hPad + 20 + 14;

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFF1F5F9),
      indent: _indent,
      endIndent: _ProfilePageState._hPad,
    );
  }
}
