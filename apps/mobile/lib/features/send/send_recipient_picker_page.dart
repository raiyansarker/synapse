import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/virtual_address.dart';
import '../qr/qr_scanner_page.dart';
import 'send_page.dart';
import 'send_recipients.dart';

// =============================================================================
// SEND — PICK RECIPIENT
// =============================================================================
class SendRecipientPickerPage extends StatefulWidget {
  final bool isRequest;

  const SendRecipientPickerPage({super.key, this.isRequest = false});

  @override
  State<SendRecipientPickerPage> createState() => _SendRecipientPickerPageState();
}

class _SendRecipientPickerPageState extends State<SendRecipientPickerPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _normalizedQuery => _query.trim().toLowerCase();

  List<SendRecipient> get _filtered {
    final q = _normalizedQuery;
    if (q.isEmpty) return kSendRecipients;
    return kSendRecipients.where((r) {
      return r.name.toLowerCase().contains(q) || r.virtualAddress.contains(q);
    }).toList();
  }

  bool get _showCustomAddressAction {
    final q = _normalizedQuery;
    if (q.isEmpty || !isVirtualAddress(q)) return false;
    return !kSendRecipients.any((r) => r.virtualAddress == q);
  }

  Future<void> _openScanner() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (!mounted || raw == null) return;
    final code = resolvePaymentTarget(raw) ?? raw;
    if (!isVirtualAddress(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read a valid payment address from that QR')),
      );
      return;
    }
    _goToAmount(sendRecipientFromCode(code));
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _goToAmount(SendRecipient recipient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendPage(
          recipient: recipient,
          isRequest: widget.isRequest,
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_showCustomAddressAction && _filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _CustomAddressButton(
            address: _normalizedQuery,
            isRequest: widget.isRequest,
            onTap: () => _goToAmount(sendRecipientFromCode(_normalizedQuery)),
          ),
        ),
      );
    }

    if (_filtered.isEmpty && _normalizedQuery.isNotEmpty) {
      return _EmptySearchState(query: _query.trim());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: _filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final person = _filtered[index];
        return _RecipientTile(
          recipient: person,
          onTap: () => _goToAmount(person),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRequest ? 'Request Money' : 'Send Money';

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: kBlack, fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Scan QR',
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded, color: kBlack),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 16, color: kBlack, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search name or @address',
                hintStyle: const TextStyle(color: kTextGrey, fontSize: 16),
                prefixIcon: const Icon(Icons.search_rounded, color: kTextGrey, size: 22),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel_rounded, color: kTextGrey, size: 22),
                      ),
                filled: true,
                fillColor: kBgGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_normalizedQuery.isEmpty || _filtered.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'People',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kBlack.withValues(alpha: 0.45),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }
}

class _CustomAddressButton extends StatelessWidget {
  final String address;
  final bool isRequest;
  final VoidCallback onTap;

  const _CustomAddressButton({
    required this.address,
    required this.isRequest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = isRequest ? 'Request from this address' : 'Send to this address';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.alternate_email_rounded, size: 44, color: kBlack.withValues(alpha: 0.35)),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          address,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: kTextGrey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String query;

  const _EmptySearchState({required this.query});

  @override
  Widget build(BuildContext context) {
    final hint = isVirtualAddress(query.toLowerCase())
        ? null
        : 'Use format username@bank (e.g. raiyan@ucb)';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: kTextGrey.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              'No matches for “$query”',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: kTextGrey, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final SendRecipient recipient;
  final VoidCallback onTap;

  const _RecipientTile({required this.recipient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(recipient.avatarUrl),
                backgroundColor: kBgGrey,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipient.virtualAddress,
                      style: const TextStyle(fontSize: 14, color: kTextGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kTextGrey, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
