/// Virtual address rules match backend `synapse.common.VirtualAddress`:
/// `username@bank` with username `[a-z0-9]+` and bank `[a-z]+`.
final RegExp _virtualAddressPattern = RegExp(r'^[a-z0-9]+@[a-z]+$');

bool isVirtualAddress(String? value) {
  if (value == null || value.isEmpty) return false;
  return _virtualAddressPattern.hasMatch(value);
}

/// Resolves a scanned QR or pasted string to a virtual address when possible.
String? resolvePaymentTarget(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (isVirtualAddress(trimmed)) return trimmed;

  if (trimmed.startsWith('synapse://pay') || trimmed.startsWith('wallet://pay')) {
    try {
      final to = Uri.parse(trimmed).queryParameters['to'];
      if (to != null && isVirtualAddress(to)) return to;
    } catch (_) {}
  }

  if (trimmed.contains('code=')) {
    try {
      final code = Uri.parse(trimmed).queryParameters['code'];
      if (code != null && isVirtualAddress(code)) return code;
    } catch (_) {}
  }

  return null;
}
