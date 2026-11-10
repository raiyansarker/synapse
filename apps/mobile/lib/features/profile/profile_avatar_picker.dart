import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/avatar_image.dart';
import 'profile_avatar_crop_page.dart';

enum _ProfilePhotoAction { gallery, camera, remove }

/// Bottom sheet: gallery, camera, remove. Runs pick + circular crop when needed.
Future<void> showProfilePhotoPickerSheet(
  BuildContext context, {
  required ValueChanged<String?> onAvatarPathChanged,
  required bool hasCustomPhoto,
  String? currentAvatarPath,
}) async {
  const ink = Color(0xFF0F172A);
  const divider = Color(0xFFF1F5F9);

  final action = await showModalBottomSheet<_ProfilePhotoAction>(
    context: context,
    backgroundColor: Colors.white,
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
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Profile Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                'Choose a photo, then crop with the round guide.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: ink),
              title: const Text('Choose from Gallery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, _ProfilePhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: ink),
              title: const Text('Take Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, _ProfilePhotoAction.camera),
            ),
            if (hasCustomPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFEF4444)),
                ),
                onTap: () => Navigator.pop(ctx, _ProfilePhotoAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == _ProfilePhotoAction.remove) {
    await deleteAvatarFile(currentAvatarPath);
    onAvatarPathChanged(null);
    return;
  }

  final source = action == _ProfilePhotoAction.gallery ? ImageSource.gallery : ImageSource.camera;

  try {
    final path = await pickAndCropProfileAvatar(
      context,
      source: source,
      replacePath: currentAvatarPath,
    );
    if (!context.mounted) return;
    if (path != null) {
      onAvatarPathChanged(path);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your photo. Please try again.')),
      );
    }
  }
}

Future<String?> pickAndCropProfileAvatar(
  BuildContext context, {
  required ImageSource source,
  String? replacePath,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 92,
    maxWidth: 2048,
    maxHeight: 2048,
  );
  if (picked == null) return null;
  if (!context.mounted) return null;

  final bytes = await picked.readAsBytes();
  if (!context.mounted) return null;

  final croppedBytes = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ProfileAvatarCropPage(imageBytes: bytes),
    ),
  );
  if (croppedBytes == null) return null;

  return persistAvatarBytes(croppedBytes, replacePath: replacePath);
}
