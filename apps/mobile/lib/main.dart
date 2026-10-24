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

// ============================================================================
// BACKEND DEVELOPER INTEGRATION GUIDE
// ============================================================================
// 1. AUTHENTICATION (Bank Login):
//    - The user logs in using: Bank Name, Account Name, Bank ID.
//    - API Endpoint required: POST `/auth/login`
//      Payload: { "bankName": "Islami Bank", "accountName": "Niggustak", "bankId": "123456789" }
//      Response: { "token": "jwt_token", "user": { "id": "1", "name": "Niggustak", "bank": "..." } }
//    - If the Bank ID does not exist in the banking API, return 404.
//
// 2. BIOMETRICS:
//    - The frontend handles biometrics locally via `local_auth`.
//    - For high-security transactions (Send Money), the backend should issue a 
//      short-lived "biometric_token" after a successful local auth, or use device binding.
//
// 3. SEND MONEY (Bank Check & Transfer):
//    - Before showing the amount, the app asks the backend: GET `/bank/verify-code?code={code}`
//      If valid, it returns the recipient's name.
//    - To send money: POST `/transfer`
//      Payload: { "recipientCode": "...", "amount": 500, "biometricVerified": true }
//
// 4. TRANSACTIONS & CHART:
//    - Replace `allTransactions` and `_monthlyReceived/Sent` with:
//      GET `/transactions` and GET `/analytics/cashflow`
//
// NOTE FOR ANDROID: To make biometrics work on Android, you must change
// `MainActivity.kt` to extend `FlutterFragmentActivity()` instead of `FlutterActivity()`.
// ============================================================================

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isBanglaNotifier = ValueNotifier(false);
final ValueNotifier<bool> authNotifier = ValueNotifier(false);

final LocalAuthentication _localAuth = LocalAuthentication();

String tr(String en, String bn) => isBanglaNotifier.value ? bn : en;

String toBanglaDigits(String input) {
  if (!isBanglaNotifier.value) return input;
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  String result = input;
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll(en[i], bn[i]);
  }
  return result;
}

String translateTxTitle(String title) {
  if (!isBanglaNotifier.value) return title;
  final map = {
    'Shopping at Daraz': 'দারাজে কেনাকাটা',
    'DIU Transport': 'ডিআইইউ ট্রান্সপোর্ট',
    'Send Money to Raiyan': 'রায়ানকে টাকা পাঠানো',
    'Freelance Payment': 'ফ্রিল্যান্স পেমেন্ট',
    'Grocery Store': 'মুদি দোকান',
    'Coffee Shop': 'কফি শপ',
    'Electricity Bill': 'বিদ্যুৎ বিল',
    'Salary Deposit': 'বেতন জমা',
    'Netflix': 'নেটফ্লিক্স',
    'Restaurant': 'রেস্টুরেন্ট',
    'Online Shopping': 'অনলাইন কেনাকাটা',
    'Gym Membership': 'জিম মেম্বারশিপ',
  };
  return map[title] ?? title;
}

String translateTxSubtitle(String subtitle) {
  if (!isBanglaNotifier.value) return subtitle;
  final map = {
    'Payment': 'পেমেন্ট',
    'Income': 'আয়',
    'Bills': 'বিল',
    'Subscription': 'সাবস্ক্রিপশন',
  };
  return map[subtitle] ?? subtitle;
}

String translateTxTime(String time) {
  if (!isBanglaNotifier.value) return time;
  String t = toBanglaDigits(time);
  return t.replaceAll('am', 'AM').replaceAll('pm', 'PM');
}

class UserState {
  final String name;
  final String? avatarPath;
  final String bankName;
  final String bankId;
  final bool isBiometricEnabled;
  
  const UserState({
    required this.name, 
    this.avatarPath,
    this.bankName = 'Islami Bank',
    this.bankId = '',
    this.isBiometricEnabled = false,
  });
  
  UserState copyWith({
    String? name, 
    String? avatarPath,
    String? bankName,
    String? bankId,
    bool? isBiometricEnabled,
  }) => UserState(
    name: name ?? this.name,
    avatarPath: avatarPath ?? this.avatarPath,
    bankName: bankName ?? this.bankName,
    bankId: bankId ?? this.bankId,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
  );
}

final ValueNotifier<UserState> userNotifier = ValueNotifier(const UserState(name: 'User'));

const String kDefaultAvatar =
    'https://i.postimg.cc/QMYSkGhW/Gemini-Generated-Image-mqgujnmqgujnmqgu.jpg';

class Tx {
  final String title;
  final String subtitle;
  final double amount;
  final String time;
  final DateTime date;
  final IconData icon;
  
  const Tx(this.title, this.subtitle, this.amount, this.time, this.date, this.icon);
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

double get totalBalance => allTransactions.fold(0.0, (sum, t) => sum + t.amount);

List<double> _monthlyReceived() {
  final r = List<double>.filled(8, 0);
  for (final t in allTransactions) {
    if (t.amount > 0 && t.date.month >= 5 && t.date.month <= 12) {
      r[t.date.month - 5] += t.amount;
    }
  }
  return r;
}

List<double> _monthlySent() {
  final r = List<double>.filled(8, 0);
  for (final t in allTransactions) {
    if (t.amount < 0 && t.date.month >= 5 && t.date.month <= 12) {
      r[t.date.month - 5] += -t.amount;
    }
  }
  return r;
}

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
  return toBanglaDigits('$sign৳${buf.toString()}.${parts[1]}');
}

String _formatK(double v) {
  String raw = v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
  return toBanglaDigits(raw);
}

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color _pageTop(BuildContext c) => _isDark(c) ? const Color(0xFF0D1A14) : const Color(0xFFE8F5E9);
Color _pageBottom(BuildContext c) => _isDark(c) ? const Color(0xFF050A08) : const Color(0xFFF9FBE7);
Color _surfaceCard(BuildContext c) => _isDark(c) ? const Color(0xFF142620) : Colors.white;
Color _heroCard(BuildContext c) => _isDark(c) ? const Color(0xFF1A3029) : Colors.white;
Color _onHero(BuildContext c) => _isDark(c) ? Colors.white : const Color(0xFF1A1A1A);
Color _onHeroMuted(BuildContext c) => _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;
Color _onHeroSubtle(BuildContext c) => _isDark(c) ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06);
Color _buttonBg(BuildContext c) => _isDark(c) ? const Color(0xFF00A86B) : const Color(0xFF006A4E);
Color _onButton(BuildContext c) => Colors.white;
Color _muted(BuildContext c) => _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;
Color _subtle(BuildContext c) => _isDark(c) ? Colors.grey[500]! : Colors.grey[600]!;
Color _iconBg(BuildContext c) => _isDark(c) ? const Color(0xFF1F382F) : const Color(0xFFE8F5E9);
Color _shadow(BuildContext c) => Colors.black.withValues(alpha: _isDark(c) ? 0.4 : 0.06);

const Color kReceivedColor = Color(0xFF006A4E);
const Color kSentColor = Color(0xFFF42A41);

ImageProvider _avatarProvider(UserState u) => u.avatarPath != null
    ? FileImage(File(u.avatarPath!))
    : const NetworkImage(kDefaultAvatar) as ImageProvider;

Future<bool> _authenticateBiometrics(BuildContext context) async {
  try {
    final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

    if (!canAuthenticate) {
      // Fallback simulation for emulators without biometrics
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Biometric Simulation'),
          content: const Text('Biometrics not available on this device. Simulate fingerprint/face ID?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simulate Success')),
          ],
        ),
      ) ?? false;
    }

    return await _localAuth.authenticate(
      localizedReason: tr('Please authenticate to proceed', 'এগিয়ে যেতে প্রমাণীকরণ করুন'),
      options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  } catch (e) {
    return false;
  }
}

Future<void> _shareInvoice(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String amount,
  required String time,
}) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  final userName = userNotifier.value.name;
  
  final safeAmount = amount.replaceAll('৳', 'BDT ');
  final safeTitle = translateTxTitle(title);
  final safeSubtitle = translateTxSubtitle(subtitle);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INVOICE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Transaction Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(height: 32, thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text('Invoice No: INV-${now.millisecondsSinceEpoch}', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('Date: $dateStr  $time', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 32),
          pw.Text('BILL TO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(userName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
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
                        pw.Text(safeTitle, style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text(safeSubtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text(safeAmount, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text(safeAmount, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text('Thank you for your business.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('This is a system-generated invoice.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: 'invoice_${now.millisecondsSinceEpoch}.pdf');
}

void main() => runApp(const MainApp());

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (context, isLoggedIn, _) {
        return isLoggedIn ? const HomeShell() : const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _bankIdController = TextEditingController();
  String _selectedBank = 'Islami Bank';
  bool _isLoading = false;

  final List<String> _banks = [
    'Islami Bank',
    'BRAC Bank',
    'IBL Bank',
    'South East Bank',
  ];

  void _login() async {
    if (_nameController.text.trim().isEmpty || _bankIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Please enter all details', 'সমস্ত বিবরণ লিখুন'))),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_bankIdController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Invalid Bank ID. No account found.', 'অবৈধ ব্যাংক আইডি। কোনো অ্যাকাউন্ট পাওয়া যায়নি।'))),
      );
      return;
    }

    userNotifier.value = UserState(
      name: _nameController.text.trim(),
      bankName: _selectedBank,
      bankId: _bankIdController.text.trim(),
      isBiometricEnabled: false,
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
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 20,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isBanglaNotifier,
                  builder: (context, isBangla, _) => TextButton.icon(
                    onPressed: () => isBanglaNotifier.value = !isBangla,
                    icon: const Icon(Icons.language, color: Color(0xFF006A4E)),
                    label: Text(
                      isBangla ? 'English' : 'বাংলা',
                      style: const TextStyle(color: Color(0xFF006A4E), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isBanglaNotifier,
                    builder: (context, _, __) {
                      return Column(
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
                                    shaderCallback: (Rect bounds) {
                                      return const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF006A4E), Color(0xFF00A86B), Color(0xFFF42A41)],
                                      ).createShader(bounds);
                                    },
                                    child: SvgPicture.asset(
                                      'assets/images/logo.svg',
                                      fit: BoxFit.contain,
                                      placeholderBuilder: (context) => const Icon(Icons.account_balance_wallet, color: Color(0xFF006A4E), size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            tr('Bank Login', 'ব্যাংক লগইন'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('Select your bank and enter your ID', 'আপনার ব্যাংক নির্বাচন করুন এবং আইডি দিন'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted(context)),
                          ),
                          const SizedBox(height: 40),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: _surfaceCard(context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance, color: Color(0xFF006A4E)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBank,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down),
                                      items: _banks.map((String bank) {
                                        return DropdownMenuItem<String>(value: bank, child: Text(bank));
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) setState(() => _selectedBank = newValue);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceCard(context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: tr('Account Holder Name', 'অ্যাকাউন্ট হোল্ডারের নাম'),
                                prefixIcon: const Icon(Icons.person_outline),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceCard(context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: TextField(
                              controller: _bankIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: tr('Bank ID Number', 'ব্যাংক আইডি নম্বর'),
                                prefixIcon: const Icon(Icons.credit_card),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonBg(context),
                                foregroundColor: _onButton(context),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      tr('Sign In securely', 'নিরাপদে সাইন ইন করুন'),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isBanglaNotifier,
      builder: (context, isBangla, _) {
        final pages = [
          const HomePage(),
          const SendPage(),
          const ReceivePage(),
          const ProfilePage(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedItemColor: _isDark(context) ? const Color(0xFF00A86B) : const Color(0xFF006A4E),
            unselectedItemColor: _isDark(context) ? Colors.grey[500] : Colors.grey,
            backgroundColor: _surfaceCard(context),
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: tr('Home', 'হোম')),
              BottomNavigationBarItem(icon: const Icon(Icons.north_east), label: tr('Send', 'পাঠান')),
              BottomNavigationBarItem(icon: const Icon(Icons.south_west), label: tr('Receive', 'গ্রহণ')),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: tr('Profile', 'প্রোফাইল')),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = allTransactions.take(4).toList();
    final receivedData = _monthlyReceived();
    final sentData = _monthlySent();

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
                    border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Transaction Overview', 'লেনদেনের সারসংক্ষেপ'),
                              style: TextStyle(color: _onHero(context), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(color: kReceivedColor, label: tr('Received', 'প্রাপ্ত'), isDarkText: false),
                              const SizedBox(width: 12),
                              _LegendDot(color: kSentColor, label: tr('Sent', 'প্রেরিত'), isDarkText: false),
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
                              received: receivedData,
                              sent: sentData,
                              isBangla: isBanglaNotifier.value,
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
                  Text(tr('Recent Transaction', 'সাম্প্রতিক লেনদেন'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsPage())),
                    child: Text(
                      tr('See All', 'সব দেখুন'),
                      style: TextStyle(color: _subtle(context), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < recent.length; i++) ...[
                _TransactionTile(tx: recent[i]),
                if (i != recent.length - 1) const SizedBox(height: 10),
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
  final bool isDarkText;

  const _LegendDot({required this.color, required this.label, required this.isDarkText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: isDarkText ? Colors.grey[700] : _onHeroMuted(context))),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isBanglaNotifier,
      builder: (context, isBangla, _) {
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
                      Text(tr('Welcome Back', 'স্বাগতম'), style: TextStyle(color: _muted(context), fontSize: 12)),
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tr('Total Balance', 'মোট ব্যালেন্স'), style: TextStyle(color: _muted(context), fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(formatMoney(totalBalance), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  ],
                ),
              ],
            );
          },
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

    final displayTitle = translateTxTitle(tx.title);
    final displaySubtitle = translateTxSubtitle(tx.subtitle);
    final displayTime = translateTxTime(tx.time);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _shareInvoice(context, title: tx.title, subtitle: tx.subtitle, amount: amountStr, time: tx.time),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: _surfaceCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _iconBg(context), shape: BoxShape.circle),
                child: Icon(tx.icon, size: 20, color: _onHero(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(displaySubtitle, style: TextStyle(color: _subtle(context), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: amountColor)),
                  const SizedBox(height: 4),
                  Text(displayTime, style: TextStyle(color: _subtle(context), fontSize: 12)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.file_download_outlined, size: 18, color: _subtle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color gridColor;
  final Color labelColor;
  final List<double> received;
  final List<double> sent;
  final bool isBangla;

  _ChartPainter({required this.gridColor, required this.labelColor, required this.received, required this.sent, required this.isBangla});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;

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
      final tp = TextPainter(text: TextSpan(text: _formatK(v), style: yTextStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
    }

    final monthsEn = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsBn = ['মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্ট', 'অক্টো', 'নভে', 'ডিসে'];
    final months = isBangla ? monthsBn : monthsEn;

    for (int i = 0; i < received.length; i++) {
      final dx = received.length > 1 ? (i / (received.length - 1)) : 0.5;
      final x = left + dx * chartW;
      final tp = TextPainter(text: TextSpan(text: months[i], style: xTextStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, top + chartH + 6));
    }

    Offset pt(int i, double v) {
      final dx = received.length > 1 ? (i / (received.length - 1)) : 0.5;
      final x = left + dx * chartW;
      final y = top + chartH - (v / maxVal) * chartH;
      return Offset(x, y);
    }

    final sentPaint = Paint()..color = kSentColor..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final sentPath = Path();
    for (int i = 0; i < sent.length; i++) {
      final p = pt(i, sent[i]);
      if (i == 0) { sentPath.moveTo(p.dx, p.dy); } else { sentPath.lineTo(p.dx, p.dy); }
    }
    _drawDashedPath(canvas, sentPath, sentPaint);

    final recPaint = Paint()..color = kReceivedColor..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final recPath = Path();
    for (int i = 0; i < received.length; i++) {
      final p = pt(i, received[i]);
      if (i == 0) { recPath.moveTo(p.dx, p.dy); } else { recPath.lineTo(p.dx, p.dy); }
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
      old.isBangla != isBangla || old.gridColor != gridColor || old.labelColor != labelColor || !listEquals(old.received, received) || !listEquals(old.sent, sent);
}

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

  void _processSend(BuildContext context) async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Enter a code first', 'প্রথমে একটি কোড লিখুন'))));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isChecking = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Invalid Code or Bank unreachable', 'অবৈধ কোড বা ব্যাংকে পৌঁছানো যাচ্ছে না'))));
      return;
    }

    _showAmountSheet(context, code);
  }

  void _showAmountSheet(BuildContext context, String code) {
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(color: _surfaceCard(ctx), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Enter Amount', 'পরিমাণ লিখুন'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${tr('Sending to', 'পাঠানো হচ্ছে')}: $code', style: TextStyle(color: _muted(ctx), fontSize: 14)),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text('৳', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: _isDark(ctx) ? Colors.white10 : const Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [500, 1000, 2000, 5000].map((amt) {
                    return ActionChip(
                      label: Text(toBanglaDigits('৳$amt')),
                      onPressed: () => amountController.text = amt.toString(),
                      backgroundColor: _isDark(ctx) ? Colors.white10 : const Color(0xFFE8F5E9),
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
                      final amt = double.tryParse(amountController.text) ?? 0;
                      if (amt <= 0) return;

                      if (userNotifier.value.isBiometricEnabled) {
                        bool auth = await _authenticateBiometrics(context);
                        if (!auth) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(tr('Authentication Failed', 'প্রমাণীকরণ ব্যর্থ হয়েছে')),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF006A4E),
                          content: Text(tr('Sent ৳$amt to $code securely', 'নিরাপদে ৳$amt পাঠানো হয়েছে $code-এ')),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBg(ctx),
                      foregroundColor: _onButton(ctx),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (userNotifier.value.isBiometricEnabled) ...[
                          const Icon(Icons.fingerprint, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(tr('Confirm Transfer', 'স্থানান্তর নিশ্চিত করুন'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              Text(tr('Send Money', 'টাকা পাঠান'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tr('Scan a QR code or enter a payment code', 'কিউআর কোড স্ক্যান করুন বা পেমেন্ট কোড দিন'), style: TextStyle(color: _muted(context), fontSize: 14)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('QR scanner coming soon', 'কিউআর স্ক্যানার শীঘ্রই আসছে'))),
                ),
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: _heroCard(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Stack(
                    children: [
                      const _ScannerCorners(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 64, color: _onHeroMuted(context)),
                            const SizedBox(height: 12),
                            Text(tr('Tap to scan', 'স্ক্যান করতে ট্যাপ করুন'), style: TextStyle(color: _onHero(context), fontSize: 14, fontWeight: FontWeight.w500)),
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
                  Expanded(child: Divider(color: _subtle(context).withValues(alpha: 0.4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(tr('or', 'অথবা'), style: TextStyle(color: _subtle(context), fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: _subtle(context).withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Enter code', 'কোড লিখুন'), style: TextStyle(color: _subtle(context), fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: tr('e.g. ABC-123-XYZ', 'উদাঃ ABC-123-XYZ'),
                        hintStyle: TextStyle(color: _subtle(context).withValues(alpha: 0.5), letterSpacing: 1, fontWeight: FontWeight.normal),
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
                  onPressed: _isChecking ? null : () => _processSend(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isChecking
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(tr('Verifying with Bank...', 'ব্যাংকের সাথে যাচাই করা হচ্ছে...'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Text(tr('Continue', 'চালিয়ে যান'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const len = 28.0;
    const thick = 3.0;
    const pad = 20.0;
    const color = Color(0xFF006A4E);

    Widget corner({bool top = true, bool left = true}) => Positioned(
          top: top ? pad : null,
          bottom: top ? null : pad,
          left: left ? pad : null,
          right: left ? null : pad,
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(color: color, thickness: thick, top: top, left: left),
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

  _CornerPainter({required this.color, required this.thickness, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = thickness..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final y = top ? 0.0 : size.height;
    final x = left ? 0.0 : size.width;
    final yEnd = top ? size.height : 0.0;
    final xEnd = left ? size.width : 0.0;

    canvas.drawLine(Offset(x, y), Offset(xEnd, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, yEnd), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.top != top || old.left != left;
}

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Payment code copied', 'পেমেন্ট কোড কপি করা হয়েছে'))));
  }

  void _shareCode() async {
    final text = tr(
      'Pay me using my Synapse Wallet code: $_paymentCode\n\nOr scan my QR code in the app.',
      'সিন্যাপ্স ওয়ালেট কোড ব্যবহার করে আমাকে পেমেন্ট করুন: $_paymentCode\n\nঅথবা অ্যাপে আমার কিউআর কোড স্ক্যান করুন।'
    );
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
              Text(tr('Receive Money', 'টাকা গ্রহণ করুন'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tr('Scan the QR or share your payment code', 'কিউআর স্ক্যান করুন বা পেমেন্ট কোড শেয়ার করুন'), style: TextStyle(color: _muted(context), fontSize: 14)),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _heroCard(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: QrImageView(
                        data: _qrPayload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF24252A)),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF24252A)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(tr('Scan to pay me', 'পেমেন্ট করতে স্ক্যান করুন'), style: TextStyle(color: _onHeroMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Payment code', 'পেমেন্ট কোড'), style: TextStyle(color: _subtle(context), fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text(_paymentCode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: tr('Copy', 'কপি'),
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
                  label: Text(tr('Share payment code', 'পেমেন্ট কোড শেয়ার করুন'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      _toast(tr('Profile photo updated', 'প্রোফাইল ছবি আপডেট হয়েছে'));
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: userNotifier.value.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Change name', 'নাম পরিবর্তন করুন')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: tr('Name', 'নাম')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel', 'বাতিল'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(tr('Save', 'সংরক্ষণ'))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != userNotifier.value.name) {
      userNotifier.value = userNotifier.value.copyWith(name: result);
      _toast(tr('Name updated', 'নাম আপডেট হয়েছে'));
    }
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
              Text(tr('Profile', 'প্রোফাইল'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(tr('Manage your account', 'আপনার অ্যাকাউন্ট পরিচালনা করুন'), style: TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 24),
              ValueListenableBuilder<UserState>(
                valueListenable: userNotifier,
                builder: (context, user, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(radius: 48, backgroundImage: _avatarProvider(user)),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(color: Color(0xFF006A4E), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance, size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text('${user.bankName} • ID: ${user.bankId}', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w500)),
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
                  border: Border.all(color: _isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                  boxShadow: [BoxShadow(color: _shadow(context), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(tr('Change name', 'নাম পরিবর্তন করুন')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editName,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<UserState>(
                      valueListenable: userNotifier,
                      builder: (context, user, _) => SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: Text(tr('Biometric Security', 'বায়োমেট্রিক নিরাপত্তা')),
                        subtitle: Text(tr('Use for login and transfers', 'লগইন এবং ট্রান্সফারের জন্য ব্যবহার করুন')),
                        value: user.isBiometricEnabled,
                        activeColor: const Color(0xFF006A4E),
                        onChanged: (v) async {
                          if (v) {
                            bool success = await _authenticateBiometrics(context);
                            if (success) {
                              userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: true);
                              _toast(tr('Biometrics enabled', 'বায়োমেট্রিক্স চালু হয়েছে'));
                            }
                          } else {
                            userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: false);
                            _toast(tr('Biometrics disabled', 'বায়োমেট্রিক্স বন্ধ হয়েছে'));
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: darkModeNotifier,
                      builder: (context, isDark, _) => SwitchListTile(
                        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                        title: Text(tr('Dark mode', 'ডার্ক মোড')),
                        value: isDark,
                        activeColor: const Color(0xFF006A4E),
                        onChanged: (v) => darkModeNotifier.value = v,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: isBanglaNotifier,
                      builder: (context, isBangla, _) => SwitchListTile(
                        secondary: const Icon(Icons.language),
                        title: Text(tr('Bangla Language', 'বাংলা ভাষা')),
                        value: isBangla,
                        activeColor: const Color(0xFF006A4E),
                        onChanged: (v) => isBanglaNotifier.value = v,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Color(0xFFF42A41)),
                      title: Text(tr('Log out', 'লগ আউট'), style: const TextStyle(color: Color(0xFFF42A41))),
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(tr('Log out?', 'লগ আউট করবেন?')),
                          content: Text(tr('Are you sure you want to log out?', 'আপনি কি নিশ্চিত যে আপনি লগ আউট করতে চান?')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel', 'বাতিল'))),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                authNotifier.value = false;
                              },
                              child: Text(tr('Log out', 'লগ আউট'), style: const TextStyle(color: Color(0xFFF42A41))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Text('v1.0.0', style: TextStyle(color: muted, fontSize: 12))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isBanglaNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('All Transactions', 'সব লেনদেন')),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _TransactionTile(tx: allTransactions[i]),
              ),
            ),
          ),
        );
      },
    );
  }
}