import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Full-screen circular crop (pinch / drag). Returns image bytes or `null`.
class ProfileAvatarCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const ProfileAvatarCropPage({super.key, required this.imageBytes});

  @override
  State<ProfileAvatarCropPage> createState() => _ProfileAvatarCropPageState();
}

class _ProfileAvatarCropPageState extends State<ProfileAvatarCropPage> {
  static const Color _ink = Color(0xFF0F172A);

  final CropController _controller = CropController();
  bool _cropping = false;

  void _onUsePhoto() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.cropCircle();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    setState(() => _cropping = false);

    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, croppedImage);
      case CropFailure(:final cause):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not crop image: $cause')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _ink),
          onPressed: _cropping ? null : () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Crop Photo',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink),
        ),
        actions: [
          TextButton(
            onPressed: _cropping ? null : _onUsePhoto,
            child: _cropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                  )
                : const Text(
                    'Use Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              withCircleUi: true,
              interactive: true,
              maskColor: Colors.black.withValues(alpha: 0.58),
              baseColor: const Color(0xFF111827),
              radius: 0,
              onCropped: _onCropped,
            ),
          ),
          Container(
            width: double.infinity,
            color: kWhite,
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.paddingOf(context).bottom),
            child: const Text(
              'Pinch to zoom · drag to move · output is a round profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
