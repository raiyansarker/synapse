import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_colors.dart';

ImageProvider userAvatarProvider(String? path) {
  if (path != null && File(path).existsSync()) {
    return FileImage(File(path));
  }
  return const NetworkImage(kDefaultAvatar) as ImageProvider;
}

Future<void> deleteAvatarFile(String? path) async {
  if (path == null) return;
  final file = File(path);
  if (file.existsSync()) {
    imageCache.evict(FileImage(file));
    try {
      await file.delete();
    } catch (_) {}
  }
}

Future<String> persistAvatarBytes(Uint8List bytes, {String? replacePath}) async {
  await deleteAvatarFile(replacePath);
  final dir = await getApplicationDocumentsDirectory();
  final dest = File('${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await dest.writeAsBytes(bytes, flush: true);
  return dest.path;
}
