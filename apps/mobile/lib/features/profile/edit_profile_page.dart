import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/avatar_image.dart';
import 'profile_avatar_picker.dart';
import '../../core/state/app_state.dart';
import '../../models/user_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const double _hPad = 20;
  static const Color _ink = Color(0xFF0F172A);
  static const Color _avatarBg = Color(0xFFF1F5F9);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = userNotifier.value;
    _nameCtrl = TextEditingController(text: u.name.isEmpty ? kHardcodedName : u.name);
    _emailCtrl = TextEditingController(text: u.email);
    _phoneCtrl = TextEditingController(text: u.phone);
    _avatarPath = u.avatarPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    await showProfilePhotoPickerSheet(
      context,
      hasCustomPhoto: _avatarPath != null,
      currentAvatarPath: _avatarPath,
      onAvatarPathChanged: (path) {
        setState(() => _avatarPath = path);
        userNotifier.value = userNotifier.value.copyWith(avatarPath: path);
      },
    );
  }

  String? _validate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return 'Enter your display name';

    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return 'Enter a valid email address';

    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(Duration.zero);

    userNotifier.value = userNotifier.value.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      avatarPath: _avatarPath,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _ink,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ValueListenableBuilder<UserState>(
        valueListenable: userNotifier,
        builder: (context, user, _) {
          return ListView(
            padding: EdgeInsets.only(bottom: bottomInset + 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
                child: Center(
                  child: GestureDetector(
                    onTap: _changePhoto,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          key: ValueKey(_avatarPath),
                          radius: 46,
                          backgroundColor: _avatarBg,
                          backgroundImage: userAvatarProvider(_avatarPath),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _ink,
                              shape: BoxShape.circle,
                              border: Border.all(color: kWhite, width: 2.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 15, color: kWhite),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _changePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: _ink),
                    label: const Text(
                      'Change profile photo',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _EditField(
                  controller: _nameCtrl,
                  label: 'Display name',
                  hint: 'Your name',
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _EditField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: _EditField(
                  controller: _phoneCtrl,
                  label: 'Mobile',
                  hint: 'Optional',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 0),
                child: _ReadOnlyField(
                  label: 'Payment ID',
                  value: user.virtualAddress,
                  footnote: 'Used on your QR code. This can’t be changed here.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _EditField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  static const Color _ink = Color(0xFF0F172A);
  static const Color _hint = Color(0xFF94A3B8);
  static const Color _fieldBorder = Color(0xFFD1D5DB);

  static final OutlineInputBorder _outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _fieldBorder, width: 1),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: _ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 16, color: _hint),
            filled: true,
            fillColor: kWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: _outline,
            focusedBorder: _outline.copyWith(
              borderSide: const BorderSide(color: _ink, width: 1.5),
            ),
            disabledBorder: _outline,
            border: _outline,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String footnote;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.footnote,
  });

  static const Color _ink = Color(0xFF0F172A);
  static const Color _hint = Color(0xFF94A3B8);
  static const Color _fieldBorder = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _fieldBorder, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _ink),
                ),
              ),
              const Icon(Icons.lock_outline_rounded, size: 18, color: _hint),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          footnote,
          style: const TextStyle(fontSize: 13, color: _hint, height: 1.4),
        ),
      ],
    );
  }
}
