// =============================================================================
// SEND — RECIPIENT DIRECTORY (mock contacts)
// =============================================================================

class SendRecipient {
  final String name;
  final String virtualAddress;
  final String avatarUrl;

  const SendRecipient({
    required this.name,
    required this.virtualAddress,
    required this.avatarUrl,
  });
}

String sendRecipientAvatarUrl(String name) {
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=128&background=E5E7EB&color=0F172A&bold=true';
}

const List<SendRecipient> kSendRecipients = [
  SendRecipient(
    name: 'Nusrat Jahan',
    virtualAddress: 'nusrat@ucb',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=256&auto=format&fit=crop',
  ),
  SendRecipient(
    name: 'Karim Hassan',
    virtualAddress: 'karim@dbbl',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=256&auto=format&fit=crop',
  ),
  SendRecipient(
    name: 'Ayesha Rahman',
    virtualAddress: 'ayesha@brac',
    avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=256&auto=format&fit=crop',
  ),
  SendRecipient(
    name: 'Rafi Ahmed',
    virtualAddress: 'rafi@city',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=256&auto=format&fit=crop',
  ),
  SendRecipient(
    name: 'Maya Chowdhury',
    virtualAddress: 'maya@ucb',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=256&auto=format&fit=crop',
  ),
  SendRecipient(
    name: 'Tanvir Islam',
    virtualAddress: 'tanvir@dbbl',
    avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=256&auto=format&fit=crop',
  ),
];

SendRecipient sendRecipientFromCode(String virtualAddress) {
  final normalized = virtualAddress.trim().toLowerCase();
  for (final r in kSendRecipients) {
    if (r.virtualAddress == normalized) return r;
  }
  final handle = normalized.split('@').first;
  final label = handle.isEmpty ? normalized : handle[0].toUpperCase() + handle.substring(1);
  return SendRecipient(
    name: label,
    virtualAddress: normalized,
    avatarUrl: sendRecipientAvatarUrl(label),
  );
}
