// =============================================================================
// ARCHITECTURE (Frontend Developers)
// =============================================================================
// State is handled with ValueNotifier + ValueListenableBuilder:
//   darkModeNotifier  : bool       - light/dark theme toggle
//   authNotifier      : bool       - logged-in gate (HomeShell vs LoginPage)
//   userNotifier      : UserState  - profile name / id / avatar / biometrics
//
// Persistence is wired up in main() via listeners on those notifiers using
// SharedPreferences. Keys used:
//   dark_mode, user_name, user_bank_id,
//   biometric_enabled, user_avatar
//
// Swapping mock data for real APIs:
//   1. Replace `allTransactions` (and its derived `_recentTransactions`,
//      `_receivedChart`, `_sentChart`, `totalBalance`) with a
//      ValueNotifier<List<Tx>> fed by GET /transactions and GET /balance.
//   2. Replace `_paymentCode` / `_qrPayload` in ReceivePage with values from
//      GET /me/payment-code.
//   3. The invoice PDF (_shareInvoice) is generated fully on-device — no
//      backend endpoint needed for receipts.
//
// =============================================================================
// BACKEND INTEGRATION GUIDE
// =============================================================================
// AUTH
//   POST /auth/login
//     Body: { "name": "...", "accountId": "..." }
//     Resp: { "token": "jwt...",
//             "user": { "id":"1","name":"...","accountId":"...",
//                       "avatarUrl":"..." } }
//   Store the token in secure storage; include as
//   `Authorization: Bearer <token>` on subsequent requests.
//
// TRANSACTIONS
//   GET /transactions?from=YYYY-MM&to=YYYY-MM
//     Resp: [ { "id":"tx_1", "title":"...", "category":"Payment|Income|Bills|Subscription",
//               "amount": -248.59, "createdAt": "2025-12-15T20:43:00Z" } ]
//   GET /balance
//     Resp: { "available": 1234.56, "currency": "BDT" }
//
// TRANSFER
//   POST /transfer
//     Body: { "recipientCode": "PAY-7K2D-9XFQ",
//             "amount": 500.0,
//             "biometricVerified": true }
//     Resp: { "transactionId":"txn_...", "status":"completed" }
//   Biometric verification itself happens entirely on-device via local_auth.
//   The backend only needs the `biometricVerified` boolean flag.
//
// RECEIVE (own payment code + QR payload)
//   GET /me/payment-code
//     Resp: { "code": "PAY-7K2D-9XFQ",
//             "qr": "wallet://pay?code=PAY-7K2D-9XFQ" }
//
// QR FORMAT
//   Payments are expected as: wallet://pay?code=<CODE>
//   The scanner extracts the `code` query param; plain codes are accepted too.
// =============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// -----------------------------------------------------------------------------
// Global state
// -----------------------------------------------------------------------------

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> authNotifier = ValueNotifier(false);
final ValueNotifier<UserState> userNotifier =
    ValueNotifier(const UserState(name: 'User'));

final LocalAuthentication _localAuth = LocalAuthentication();

// -----------------------------------------------------------------------------
// Models & mock data
// -----------------------------------------------------------------------------

class UserState {
  final String name;
  final String? avatarPath;
  final String bankId;
  final bool isBiometricEnabled;

  const UserState({
    required this.name,
    this.avatarPath,
    this.bankId = '',
    this.isBiometricEnabled = false,
  });

  UserState copyWith({
    String? name,
    String? avatarPath,
    String? bankId,
    bool? isBiometricEnabled,
  }) =>
      UserState(
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
        bankId: bankId ?? this.bankId,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      );
}

class Tx {
  final String title;
  final String subtitle;
  final double amount;
  final String time;
  final DateTime date;
  final IconData icon;

  const Tx(this.title, this.subtitle, this.amount, this.time, this.date,
      this.icon);
}

final List<Tx> allTransactions = [
  Tx('Shopping at Daraz', 'Payment', -248.59, '08:43 pm',
      DateTime(2025, 12, 15, 20, 43), Icons.shopping_bag_outlined),
  Tx('DIU Transport', 'Payment', -18.00, '08:43 pm',
      DateTime(2025, 12, 14, 20, 43), Icons.directions_car_outlined),
  Tx('Send Money to Raiyan', 'Payment', -145.98, '08:43 pm',
      DateTime(2025, 12, 12, 20, 43), Icons.send_outlined),
  Tx('Freelance Payment', 'Income', 850.00, '10:20 am',
      DateTime(2025, 12, 10, 10, 20), Icons.payments_outlined),
  Tx('Grocery Store', 'Payment', -67.40, '07:12 pm',
      DateTime(2025, 12, 5, 19, 12), Icons.local_grocery_store_outlined),
  Tx('Coffee Shop', 'Payment', -8.75, '10:05 am',
      DateTime(2025, 11, 20, 10, 5), Icons.local_cafe_outlined),
  Tx('Electricity Bill', 'Bills', -42.10, '11:30 am',
      DateTime(2025, 11, 5, 11, 30), Icons.bolt_outlined),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 11, 1, 9, 15), Icons.work_outline),
  Tx('Netflix', 'Subscription', -15.99, '01:00 am',
      DateTime(2025, 10, 2, 1, 0), Icons.movie_outlined),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 10, 1, 9, 15), Icons.work_outline),
  Tx('Restaurant', 'Payment', -84.20, '08:30 pm',
      DateTime(2025, 9, 15, 20, 30), Icons.restaurant_outlined),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 9, 1, 9, 15), Icons.work_outline),
  Tx('Online Shopping', 'Payment', -120.00, '03:00 pm',
      DateTime(2025, 8, 12, 15, 0), Icons.shopping_cart_outlined),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 8, 1, 9, 15), Icons.work_outline),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 7, 1, 9, 15), Icons.work_outline),
  Tx('Gym Membership', 'Bills', -50.00, '10:00 am',
      DateTime(2025, 6, 5, 10, 0), Icons.fitness_center),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 6, 1, 9, 15), Icons.work_outline),
  Tx('Salary Deposit', 'Income', 3200.00, '09:15 am',
      DateTime(2025, 5, 1, 9, 15), Icons.work_outline),
];

// Precomputed once from the mock list — remove when switching to live APIs.
final double totalBalance =
    allTransactions.fold(0.0, (sum, t) => sum + t.amount);
final List<Tx> _recentTransactions = allTransactions.take(4).toList();

List<double> _computeMonthlyReceived() {
  final r = List<double>.filled(8, 0);
  for (final t in allTransactions) {
    if (t.amount > 0 && t.date.month >= 5 && t.date.month <= 12) {
      r[t.date.month - 5] += t.amount;
    }
  }
  return r;
}

List<double> _computeMonthlySent() {
  final r = List<double>.filled(8, 0);
  for (final t in allTransactions) {
    if (t.amount < 0 && t.date.month >= 5 && t.date.month <= 12) {
      r[t.date.month - 5] += -t.amount;
    }
  }
  return r;
}

final List<double> _receivedChart = _computeMonthlyReceived();
final List<double> _sentChart = _computeMonthlySent();

// -----------------------------------------------------------------------------
// Formatting helpers
// -----------------------------------------------------------------------------

String formatMoney(double v, {bool showSign = false}) {
  final isNeg = v < 0;
  final abs = v.abs();
  final parts = abs.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  String sign = '';
  if (isNeg) {
    sign = '-';
  } else if (showSign && v > 0) {
    sign = '+';
  }
  return '$sign৳${buf.toString()}.${parts[1]}';
}

String _formatK(double v) =>
    v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

// -----------------------------------------------------------------------------
// Theme tokens
// -----------------------------------------------------------------------------

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color _pageTop(BuildContext c) =>
    _isDark(c) ? const Color(0xFF0D1A14) : const Color(0xFFE8F5E9);
Color _pageBottom(BuildContext c) =>
    _isDark(c) ? const Color(0xFF050A08) : const Color(0xFFF9FBE7);
Color _surfaceCard(BuildContext c) =>
    _isDark(c) ? const Color(0xFF142620) : Colors.white;
Color _heroCard(BuildContext c) =>
    _isDark(c) ? const Color(0xFF1A3029) : Colors.white;
Color _onHero(BuildContext c) =>
    _isDark(c) ? Colors.white : const Color(0xFF1A1A1A);
Color _onHeroMuted(BuildContext c) =>
    _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;
Color _onHeroSubtle(BuildContext c) => _isDark(c)
    ? Colors.white.withValues(alpha: 0.1)
    : Colors.black.withValues(alpha: 0.06);
Color _buttonBg(BuildContext c) =>
    _isDark(c) ? const Color(0xFF00A86B) : const Color(0xFF006A4E);
Color _onButton(BuildContext c) => Colors.white;
Color _muted(BuildContext c) =>
    _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;
Color _subtle(BuildContext c) =>
    _isDark(c) ? Colors.grey[500]! : Colors.grey[600]!;
Color _iconBg(BuildContext c) =>
    _isDark(c) ? const Color(0xFF1F382F) : const Color(0xFFE8F5E9);
Color _shadow(BuildContext c) =>
    Colors.black.withValues(alpha: _isDark(c) ? 0.4 : 0.06);

const Color kReceivedColor = Color(0xFF006A4E);
const Color kSentColor = Color(0xFFF42A41);

const String kDefaultAvatar =
    'https://i.postimg.cc/QMYSkGhW/Gemini-Generated-Image-mqgujnmqgujnmqgu.jpg';

ImageProvider _avatarProvider(UserState u) => u.avatarPath != null
    ? FileImage(File(u.avatarPath!))
    : const NetworkImage(kDefaultAvatar) as ImageProvider;

// -----------------------------------------------------------------------------
// Biometric gate
// -----------------------------------------------------------------------------
// Returns true when the user authenticates (or explicitly simulates success
// on devices without a biometric sensor). Backend only needs the bool result.
Future<bool> _authenticateBiometrics(BuildContext context) async {
  try {
    final withBio = await _localAuth.canCheckBiometrics;
    final supported = withBio || await _localAuth.isDeviceSupported();

    if (!supported) {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Biometric Simulation'),
              content: const Text(
                  'Biometrics not available on this device. Simulate fingerprint/face ID?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simulate Success'),
                ),
              ],
            ),
          ) ??
          false;
    }

    return await _localAuth.authenticate(
      localizedReason: 'Please authenticate to proceed',
      options:
          const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  } catch (_) {
    return false;
  }
}

// -----------------------------------------------------------------------------
// PDF invoice (fully on-device, no backend endpoint required)
// -----------------------------------------------------------------------------

Future<void> _shareInvoice({
  required String title,
  required String subtitle,
  required String amount,
  required String time,
}) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final dateStr =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  final userName = userNotifier.value.name;
  // Standard PDF fonts don't include the Taka glyph — replace for the PDF only.
  final safeAmount = amount.replaceAll('৳', 'BDT ');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INVOICE',
              style: pw.TextStyle(
                  fontSize: 32, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Transaction Receipt',
              style:
                  const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(height: 32, thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text('Invoice No: INV-${now.millisecondsSinceEpoch}',
              style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('Date: $dateStr  $time',
              style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 32),
          pw.Text('BILL TO',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(userName,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 32),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Description',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Amount',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(title,
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text(subtitle,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text(safeAmount,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text(safeAmount,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text('Thank you for your business.',
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('This is a system-generated invoice.',
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(
      bytes: bytes, filename: 'invoice_${now.millisecondsSinceEpoch}.pdf');
}

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  darkModeNotifier.value = prefs.getBool('dark_mode') ?? false;

  darkModeNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', darkModeNotifier.value);
  });

  userNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    final u = userNotifier.value;
    await p.setString('user_name', u.name);
    await p.setString('user_bank_id', u.bankId);
    await p.setBool('biometric_enabled', u.isBiometricEnabled);
    if (u.avatarPath != null) await p.setString('user_avatar', u.avatarPath!);
  });

  runApp(const MainApp());
}

// -----------------------------------------------------------------------------
// App root
// -----------------------------------------------------------------------------

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF006A4E),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFE8F5E9),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF00A86B),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D1A14),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Auth wrapper — decides LoginPage vs HomeShell, with quick biometric login.
// -----------------------------------------------------------------------------

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkQuickLogin();
  }

  Future<void> _checkQuickLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final bankId = prefs.getString('user_bank_id');
      final isBioEnabled = prefs.getBool('biometric_enabled') ?? false;
      final avatar = prefs.getString('user_avatar');

      if (name != null && bankId != null && name != 'User') {
        userNotifier.value = UserState(
          name: name,
          bankId: bankId,
          isBiometricEnabled: isBioEnabled,
          avatarPath: avatar,
        );

        if (isBioEnabled) {
          final success = await _localAuth.authenticate(
            localizedReason: 'Quick Login via Biometrics',
            options: const AuthenticationOptions(
                stickyAuth: true, biometricOnly: true),
          );
          if (success) authNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading prefs: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (context, _, __) =>
          authNotifier.value ? const HomeShell() : const LoginPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// Login page
// -----------------------------------------------------------------------------
// Mock flow: waits 2s then accepts any name + accountId with >= 5 chars.
// To hook up POST /auth/login, replace the body of `_login()` with the API
// call and set `userNotifier.value` + `authNotifier.value = true` on success.
// -----------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _bankIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bankIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_nameController.text.trim().isEmpty ||
        _bankIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // TODO(backend): replace with POST /auth/login + secure token storage.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_bankIdController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Account ID. No account found.')),
      );
      return;
    }

    final current = userNotifier.value;
    userNotifier.value = UserState(
      name: _nameController.text.trim(),
      bankId: _bankIdController.text.trim(),
      isBiometricEnabled: current.isBiometricEnabled,
      avatarPath: current.avatarPath,
    );
    authNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop(context), _pageBottom(context)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF006A4E),
                                  Color(0xFF00A86B),
                                  Color(0xFFF42A41),
                                ],
                              ).createShader(bounds);
                            },
                            child: SvgPicture.asset(
                              'assets/images/logo.svg',
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF006A4E),
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted(context)),
                  ),
                  const SizedBox(height: 40),
                  _LoginField(
                    controller: _nameController,
                    hint: 'Account Holder Name',
                    icon: Icons.person_outline,
                    capitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  _LoginField(
                    controller: _bankIdController,
                    hint: 'Account ID Number',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonBg(context),
                        foregroundColor: _onButton(context),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Sign In securely',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _shadow(context),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Home shell (bottom navigation)
// -----------------------------------------------------------------------------

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomePage(),
    SendPage(),
    ReceivePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor:
            _isDark(context) ? const Color(0xFF00A86B) : const Color(0xFF006A4E),
        unselectedItemColor: _isDark(context) ? Colors.grey[500] : Colors.grey,
        backgroundColor: _surfaceCard(context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.north_east), label: 'Send'),
          BottomNavigationBarItem(
              icon: Icon(Icons.south_west), label: 'Receive'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Home page
// -----------------------------------------------------------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop(context), _pageBottom(context)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: _heroCard(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _isDark(context)
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                          color: _shadow(context),
                          blurRadius: 20,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Transaction Overview',
                              style: TextStyle(
                                  color: _onHero(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(
                                  color: kReceivedColor, label: 'Received'),
                              SizedBox(width: 12),
                              _LegendDot(color: kSentColor, label: 'Sent'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _ChartPainter(
                              gridColor: _onHeroSubtle(context),
                              labelColor: _onHeroMuted(context),
                              received: _receivedChart,
                              sent: _sentChart,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transaction',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TransactionsPage())),
                    child: Text(
                      'See All',
                      style: TextStyle(
                          color: _subtle(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _recentTransactions.length; i++) ...[
                _TransactionTile(tx: _recentTransactions[i]),
                if (i != _recentTransactions.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: _onHeroMuted(context))),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserState>(
      valueListenable: userNotifier,
      builder: (context, user, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 24, backgroundImage: _avatarProvider(user)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back',
                      style:
                          TextStyle(color: _muted(context), fontSize: 12)),
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Balance',
                    style: TextStyle(
                        color: _muted(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(formatMoney(totalBalance),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Tx tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.amount > 0;
    final amountStr = formatMoney(tx.amount, showSign: true);
    final amountColor = isIncome ? const Color(0xFF16A34A) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _shareInvoice(
          title: tx.title,
          subtitle: tx.subtitle,
          amount: amountStr,
          time: tx.time,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: _surfaceCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _isDark(context)
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _iconBg(context), shape: BoxShape.circle),
                child: Icon(tx.icon, size: 20, color: _onHero(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(tx.subtitle,
                        style: TextStyle(
                            color: _subtle(context), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountStr,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: amountColor)),
                  const SizedBox(height: 4),
                  Text(tx.time,
                      style: TextStyle(
                          color: _subtle(context), fontSize: 12)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.file_download_outlined,
                  size: 18, color: _subtle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Chart painter (received vs sent, last 8 months)
// -----------------------------------------------------------------------------

class _ChartPainter extends CustomPainter {
  final Color gridColor;
  final Color labelColor;
  final List<double> received;
  final List<double> sent;

  _ChartPainter({
    required this.gridColor,
    required this.labelColor,
    required this.received,
    required this.sent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const top = 10.0;
    const bottom = 25.0;
    const left = 35.0;
    const right = 10.0;

    final chartW = (size.width - left - right).clamp(0.0, double.infinity);
    final chartH = (size.height - top - bottom).clamp(0.0, double.infinity);

    final all = [...received, ...sent];
    final rawMax = all.isEmpty ? 0.0 : all.reduce((a, b) => a > b ? a : b);
    final maxVal = rawMax > 0 ? rawMax : 1.0;

    final yTextStyle = TextStyle(color: labelColor, fontSize: 10);
    final xTextStyle = TextStyle(color: labelColor, fontSize: 10);

    for (int i = 0; i <= 4; i++) {
      final y = top + chartH * (i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + chartW, y), gridPaint);
      final v = maxVal * (1 - i / 4);
      final tp = TextPainter(
        text: TextSpan(text: _formatK(v), style: yTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
    }

    const months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int i = 0; i < received.length; i++) {
      final dx = received.length > 1 ? (i / (received.length - 1)) : 0.5;
      final x = left + dx * chartW;
      final tp = TextPainter(
        text: TextSpan(text: months[i], style: xTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, top + chartH + 6));
    }

    Offset pt(int i, double v) {
      final dx = received.length > 1 ? (i / (received.length - 1)) : 0.5;
      final x = left + dx * chartW;
      final y = top + chartH - (v / maxVal) * chartH;
      return Offset(x, y);
    }

    final sentPaint = Paint()
      ..color = kSentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sentPath = Path();
    for (int i = 0; i < sent.length; i++) {
      final p = pt(i, sent[i]);
      if (i == 0) {
        sentPath.moveTo(p.dx, p.dy);
      } else {
        sentPath.lineTo(p.dx, p.dy);
      }
    }
    _drawDashedPath(canvas, sentPath, sentPaint);

    final recPaint = Paint()
      ..color = kReceivedColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final recPath = Path();
    for (int i = 0; i < received.length; i++) {
      final p = pt(i, received[i]);
      if (i == 0) {
        recPath.moveTo(p.dx, p.dy);
      } else {
        recPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(recPath, recPaint);

    for (int i = 0; i < received.length; i++) {
      final p = pt(i, received[i]);
      canvas.drawCircle(p, 3.5, Paint()..color = kReceivedColor);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        final end = next > metric.length ? metric.length : next;
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.gridColor != gridColor ||
      old.labelColor != labelColor ||
      !listEquals(old.received, received) ||
      !listEquals(old.sent, sent);
}

// -----------------------------------------------------------------------------
// Send page
// -----------------------------------------------------------------------------
// Hooks needed for backend:
//   - QR scanned value or typed code goes into `codeController`.
//   - POST /transfer with { recipientCode, amount, biometricVerified } inside
//     `_showAmountSheet`'s confirm button (replace the snackbar with the call).
//   - Sending is blocked unless biometrics are enabled and verified.
// -----------------------------------------------------------------------------

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final codeController = TextEditingController();
  bool _isChecking = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) codeController.text = result;
  }

  Future<void> _processSend() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a code first')),
      );
      return;
    }

    if (!userNotifier.value.isBiometricEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
              'Please enable Biometric Security in Profile to send money.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isChecking = true);

    // TODO(backend): replace with GET /recipients/:code to validate the code
    // and fetch the recipient's display name before showing the amount sheet.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Code or Bank unreachable')),
      );
      return;
    }

    _showAmountSheet(code);
  }

  void _showAmountSheet(String code) {
    final amountController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: _surfaceCard(ctx),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter Amount',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Sending to: $code',
                    style: TextStyle(color: _muted(ctx), fontSize: 14)),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text('৳',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    hintText: '0.00',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: _isDark(ctx)
                        ? Colors.white10
                        : const Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [500, 1000, 2000, 5000].map((amt) {
                    return ActionChip(
                      label: Text('৳$amt'),
                      onPressed: () => amountController.text = amt.toString(),
                      backgroundColor: _isDark(ctx)
                          ? Colors.white10
                          : const Color(0xFFE8F5E9),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt =
                          double.tryParse(amountController.text) ?? 0;
                      if (amt <= 0) return;

                      final auth = await _authenticateBiometrics(context);
                      if (!auth) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Authentication Failed'),
                            ),
                          );
                        }
                        return;
                      }

                      if (!context.mounted) return;
                      // TODO(backend): await POST /transfer here and use the
                      // returned transactionId / status in the snackbar.
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF006A4E),
                          content: Text('Sent ৳$amt to $code securely'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBg(ctx),
                      foregroundColor: _onButton(ctx),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 20),
                        SizedBox(width: 8),
                        Text('Confirm Transfer',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(amountController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop(context), _pageBottom(context)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Money',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Scan a QR code or enter a payment code',
                  style: TextStyle(color: _muted(context), fontSize: 14)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _scanQR,
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: _heroCard(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _isDark(context)
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                          color: _shadow(context),
                          blurRadius: 20,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const _ScannerCorners(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                size: 64, color: _onHeroMuted(context)),
                            const SizedBox(height: 12),
                            Text('Tap to scan',
                                style: TextStyle(
                                    color: _onHero(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: _subtle(context).withValues(alpha: 0.4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(
                            color: _subtle(context), fontSize: 13)),
                  ),
                  Expanded(
                      child: Divider(
                          color: _subtle(context).withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _isDark(context)
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [
                    BoxShadow(
                        color: _shadow(context),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter code',
                        style: TextStyle(
                            color: _subtle(context), fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'e.g. ABC-123-XYZ',
                        hintStyle: TextStyle(
                            color: _subtle(context).withValues(alpha: 0.5),
                            letterSpacing: 1,
                            fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _processSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Verifying...',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// QR scanner
// -----------------------------------------------------------------------------
// Accepts both `wallet://pay?code=...` URIs and plain text codes. The
// extracted code is returned to the caller.
// -----------------------------------------------------------------------------

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw == null) continue;

                var code = raw;
                if (raw.startsWith('wallet://pay') || raw.contains('code=')) {
                  try {
                    code = Uri.parse(raw).queryParameters['code'] ?? raw;
                  } catch (_) {}
                }
                Navigator.pop(context, code);
                return;
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF006A4E), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align QR code within the frame',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const len = 28.0;
    const thick = 3.0;
    const pad = 20.0;
    const color = Color(0xFF006A4E);

    Widget corner({required bool top, required bool left}) => Positioned(
          top: top ? pad : null,
          bottom: top ? null : pad,
          left: left ? pad : null,
          right: left ? null : pad,
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(
                  color: color, thickness: thick, top: top, left: left),
            ),
          ),
        );

    return Stack(children: [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ]);
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final y = top ? 0.0 : size.height;
    final x = left ? 0.0 : size.width;
    final yEnd = top ? size.height : 0.0;
    final xEnd = left ? size.width : 0.0;

    canvas.drawLine(Offset(x, y), Offset(xEnd, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, yEnd), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.top != top || old.left != left;
}

// -----------------------------------------------------------------------------
// Receive page
// -----------------------------------------------------------------------------
// `_paymentCode` and `_qrPayload` are mocked. Replace with values from
// GET /me/payment-code. The QR payload must match the scanner's expected
// `wallet://pay?code=<CODE>` format.
// -----------------------------------------------------------------------------

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  static const String _paymentCode = 'PAY-7K2D-9XFQ';
  static const String _qrPayload = 'wallet://pay?code=$_paymentCode';

  void _copyCode() {
    Clipboard.setData(const ClipboardData(text: _paymentCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment code copied')),
    );
  }

  Future<void> _shareCode() async {
    const text =
        'Pay me using my Synapse Wallet code: $_paymentCode\n\nOr scan my QR code in the app.';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop(context), _pageBottom(context)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Receive Money',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Scan the QR or share your payment code',
                  style: TextStyle(color: _muted(context), fontSize: 14)),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _heroCard(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: _isDark(context)
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [
                    BoxShadow(
                        color: _shadow(context),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: QrImageView(
                        data: _qrPayload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF24252A)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF24252A)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Scan to pay me',
                        style: TextStyle(
                            color: _onHeroMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _isDark(context)
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [
                    BoxShadow(
                        color: _shadow(context),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment code',
                              style: TextStyle(
                                  color: _subtle(context), fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text(_paymentCode,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share payment code',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Profile page
// -----------------------------------------------------------------------------

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      userNotifier.value = userNotifier.value.copyWith(avatarPath: picked.path);
      _toast('Profile photo updated');
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: userNotifier.value.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null &&
        result.isNotEmpty &&
        result != userNotifier.value.name) {
      userNotifier.value = userNotifier.value.copyWith(name: result);
      _toast('Name updated');
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final auth = await _authenticateBiometrics(context);
      if (auth) {
        userNotifier.value =
            userNotifier.value.copyWith(isBiometricEnabled: true);
        _toast('Biometrics enabled. Quick Login active.');
      } else {
        _toast('Authentication failed');
      }
    } else {
      userNotifier.value =
          userNotifier.value.copyWith(isBiometricEnabled: false);
      _toast('Biometrics disabled');
    }
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Keep userNotifier intact so quick biometric login still works.
              authNotifier.value = false;
            },
            child:
                const Text('Log out', style: TextStyle(color: Color(0xFFF42A41))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _surfaceCard(context);
    final muted = _muted(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pageTop(context), _pageBottom(context)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Profile',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              Text('Manage your account',
                  style: TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 24),
              ValueListenableBuilder<UserState>(
                valueListenable: userNotifier,
                builder: (context, user, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _isDark(context)
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                          color: _shadow(context),
                          blurRadius: 20,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                                radius: 48,
                                backgroundImage: _avatarProvider(user)),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                    color: Color(0xFF006A4E),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text('ID: ${user.bankId}',
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _isDark(context)
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [
                    BoxShadow(
                        color: _shadow(context),
                        blurRadius: 16,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Change name'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editName,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<UserState>(
                      valueListenable: userNotifier,
                      builder: (context, user, _) => SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: const Text('Biometric Security'),
                        subtitle: const Text(
                            'Required for Sending & Quick Login'),
                        value: user.isBiometricEnabled,
                        activeThumbColor: const Color(0xFF006A4E),
                        onChanged: _toggleBiometrics,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: darkModeNotifier,
                      builder: (context, isDark, _) => SwitchListTile(
                        secondary:
                            Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                        title: const Text('Dark mode'),
                        value: isDark,
                        activeThumbColor: const Color(0xFF006A4E),
                        onChanged: (v) => darkModeNotifier.value = v,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout,
                          color: Color(0xFFF42A41)),
                      title: const Text('Log out',
                          style: TextStyle(color: Color(0xFFF42A41))),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('v1.0.0',
                    style: TextStyle(color: muted, fontSize: 12)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// All transactions page
// -----------------------------------------------------------------------------

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: _surfaceCard(context),
        foregroundColor: _onHero(context),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageTop(context), _pageBottom(context)],
          ),
        ),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: allTransactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _TransactionTile(tx: allTransactions[i]),
          ),
        ),
      ),
    );
  }
}