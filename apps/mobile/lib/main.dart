import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ============================================================================
// BACKEND DEVELOPER INTEGRATION GUIDE
// ============================================================================
// 1. USER STATE & LANGUAGE: 
//    Currently using `userNotifier` and `isBanglaNotifier` for state.
//    - When logging in, update `userNotifier.value = UserState(name: "Name", avatarPath: "url")`.
//    - The app natively supports Bangla/English via `isBanglaNotifier`. 
//
// 2. TRANSACTIONS DATA:
//    Replace `allTransactions` with a list fetched from your API.
//
// 3. CHART DATA:
//    The chart uses `_monthlyReceived()` and `_monthlySent()`. 
//
// 4. INVOICE / PDF GENERATION:
//    Generates PDF client-side.
//
// 5. SEND / RECEIVE ACTIONS:
//    - `SendPage`: Calls a SnackBar mock. Replace with POST `/transfer`.
//    - `ReceivePage`: Hardcoded `_paymentCode`. Replace with GET `/me/qr-code`.
// ============================================================================

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> isBanglaNotifier = ValueNotifier(false);

// --- Localization Helpers ---
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
// ----------------------------

class UserState {
  final String name;
  final String? avatarPath;
  
  const UserState({required this.name, this.avatarPath});
  
  UserState copyWith({String? name, String? avatarPath}) => UserState(
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
      );
}

final ValueNotifier<UserState> userNotifier =
    ValueNotifier(const UserState(name: 'Niggustak'));

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

double get totalBalance =>
    allTransactions.fold(0.0, (sum, t) => sum + t.amount);

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

Color _pageTop(BuildContext c) =>
    _isDark(c) ? const Color(0xFF121212) : const Color(0xFFF5F2E9);

Color _pageBottom(BuildContext c) =>
    _isDark(c) ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA);

Color _surfaceCard(BuildContext c) =>
    _isDark(c) ? const Color(0xFF24252A) : Colors.white;

Color _heroCard(BuildContext c) =>
    _isDark(c) ? const Color(0xFF2E2F35) : Colors.white;

Color _onHero(BuildContext c) =>
    _isDark(c) ? Colors.white : const Color(0xFF1A1A1A);

Color _onHeroMuted(BuildContext c) =>
    _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;

Color _onHeroSubtle(BuildContext c) => _isDark(c)
    ? Colors.white.withValues(alpha: 0.1)
    : Colors.black.withValues(alpha: 0.06);

Color _buttonBg(BuildContext c) =>
    _isDark(c) ? const Color(0xFF24252A) : Colors.white;
Color _onButton(BuildContext c) => const Color(0xFFFFB300);

Color _muted(BuildContext c) =>
    _isDark(c) ? Colors.grey[400]! : Colors.grey[700]!;

Color _subtle(BuildContext c) =>
    _isDark(c) ? Colors.grey[500]! : Colors.grey[600]!;

Color _iconBg(BuildContext c) =>
    _isDark(c) ? const Color(0xFF3A3B40) : const Color(0xFFEEEEEE);

Color _shadow(BuildContext c) =>
    Colors.black.withValues(alpha: _isDark(c) ? 0.4 : 0.08);

const Color kReceivedColor = Color(0xFFFFB300);
const Color kSentColor = Color(0xFFFF6B6B);

ImageProvider _avatarProvider(UserState u) => u.avatarPath != null
    ? FileImage(File(u.avatarPath!))
    : const NetworkImage(kDefaultAvatar) as ImageProvider;

Future<void> _shareInvoice(
  BuildContext context, {
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
          pw.Text('INVOICE',
              style: pw.TextStyle(
                  fontSize: 32, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Transaction Receipt',
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey700)),
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
                        pw.Text(safeTitle,
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text(safeSubtitle,
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
    bytes: bytes,
    filename: 'invoice_${now.millisecondsSinceEpoch}.pdf',
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Invoice ready to save or share', 'ইনভয়েস তৈরি হয়েছে'))),
    );
  }
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
            colorSchemeSeed: const Color(0xFF24252A),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F2E9),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFFFB300),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: const HomeShell(),
        );
      },
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
          HomePage(),
          SendPage(),
          ReceivePage(),
          ProfilePage(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedItemColor:
                _isDark(context) ? const Color(0xFFFFB300) : Colors.black,
            unselectedItemColor:
                _isDark(context) ? Colors.grey[500] : Colors.grey,
            backgroundColor: _surfaceCard(context),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: tr('Home', 'হোম'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.north_east),
                label: tr('Send', 'পাঠান'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.south_west),
                label: tr('Receive', 'গ্রহণ'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: tr('Profile', 'প্রোফাইল'),
              ),
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
              _Header(),
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
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _shadow(context),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Transaction Overview', 'লেনদেনের সারসংক্ষেপ'),
                              style: TextStyle(
                                color: _onHero(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(
                                color: kReceivedColor,
                                label: tr('Received', 'প্রাপ্ত'),
                                isDarkText: false,
                              ),
                              const SizedBox(width: 12),
                              _LegendDot(
                                color: kSentColor,
                                label: tr('Sent', 'প্রেরিত'),
                                isDarkText: false,
                              ),
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
                  Text(
                    tr('Recent Transaction', 'সাম্প্রতিক লেনদেন'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsPage(),
                      ),
                    ),
                    child: Text(
                      tr('See All', 'সব দেখুন'),
                      style: TextStyle(
                        color: _subtle(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDarkText,
  });

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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkText ? Colors.grey[700] : _onHeroMuted(context),
          ),
        ),
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
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _avatarProvider(user),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Welcome Back', 'স্বাগতম'),
                        style: TextStyle(color: _muted(context), fontSize: 12),
                      ),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tr('Total Balance', 'মোট ব্যালেন্স'),
                      style: TextStyle(
                        color: _muted(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(totalBalance),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
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
        onTap: () => _shareInvoice(
          context,
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
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _iconBg(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(tx.icon, size: 20, color: _onHero(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displaySubtitle,
                      style:
                          TextStyle(color: _subtle(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayTime,
                    style: TextStyle(color: _subtle(context), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.file_download_outlined,
                size: 18,
                color: _subtle(context),
              ),
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

  _ChartPainter({
    required this.gridColor,
    required this.labelColor,
    required this.received,
    required this.sent,
    required this.isBangla,
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

    final monthsEn = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsBn = [
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্ট',
      'অক্টো',
      'নভে',
      'ডিসে'
    ];
    final months = isBangla ? monthsBn : monthsEn;

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
      old.isBangla != isBangla ||
      old.gridColor != gridColor ||
      old.labelColor != labelColor ||
      !listEquals(old.received, received) ||
      !listEquals(old.sent, sent);
}

class SendPage extends StatefulWidget {
  const SendPage({super.key});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
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
              Text(
                tr('Send Money', 'টাকা পাঠান'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Scan a QR code or enter a payment code',
                    'কিউআর কোড স্ক্যান করুন বা পেমেন্ট কোড দিন'),
                style: TextStyle(color: _muted(context), fontSize: 14),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          tr('QR scanner coming soon', 'কিউআর স্ক্যানার শীঘ্রই আসছে'))),
                ),
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: _heroCard(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isDark(context)
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _shadow(context),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
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
                            Text(
                              tr('Tap to scan', 'স্ক্যান করতে ট্যাপ করুন'),
                              style: TextStyle(
                                color: _onHero(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                    child: Text(tr('or', 'অথবা'),
                        style: TextStyle(
                            color: _subtle(context), fontSize: 13)),
                  ),
                  Expanded(
                      child: Divider(
                          color: _subtle(context).withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 24),
              
              // Styled to match the Receive Page Code Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceCard(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isDark(context)
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow(context),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Enter code', 'কোড লিখুন'),
                      style: TextStyle(
                          color: _subtle(context), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: tr('e.g. ABC-123-XYZ', 'উদাঃ ABC-123-XYZ'),
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
                  onPressed: () {
                    final code = codeController.text.trim();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(tr('Enter a code first',
                                'প্রথমে একটি কোড লিখুন'))),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(tr('Looking up code: $code',
                              'কোড খোঁজা হচ্ছে: $code'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    side: BorderSide(
                      color: _isDark(context)
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    tr('Continue', 'চালিয়ে যান'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners();

  @override
  Widget build(BuildContext context) {
    const len = 28.0;
    const thick = 3.0;
    const pad = 20.0;
    const color = Color(0xFFFFB300);

    Widget corner({bool top = true, bool left = true}) => Positioned(
          top: top ? pad : null,
          bottom: top ? null : pad,
          left: left ? pad : null,
          right: left ? null : pad,
          child: SizedBox(
            width: len,
            height: len,
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                thickness: thick,
                top: top,
                left: left,
              ),
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
      SnackBar(
          content: Text(
              tr('Payment code copied', 'পেমেন্ট কোড কপি করা হয়েছে'))),
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
              Text(
                tr('Receive Money', 'টাকা গ্রহণ করুন'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Scan the QR or share your payment code',
                    'কিউআর স্ক্যান করুন বা পেমেন্ট কোড শেয়ার করুন'),
                style: TextStyle(color: _muted(context), fontSize: 14),
              ),
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
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow(context),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: _qrPayload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF24252A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF24252A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('Scan to pay me', 'পেমেন্ট করতে স্ক্যান করুন'),
                      style: TextStyle(
                          color: _onHeroMuted(context), fontSize: 13),
                    ),
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
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow(context),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Payment code', 'পেমেন্ট কোড'),
                            style: TextStyle(
                                color: _subtle(context), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            _paymentCode, // Kept in English!
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(tr('Share sheet coming soon',
                              'শেয়ার শীঘ্রই আসছে')))),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(
                    tr('Share payment code', 'পেমেন্ট কোড শেয়ার করুন'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBg(context),
                    foregroundColor: _onButton(context),
                    side: BorderSide(
                      color: _isDark(context)
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
      userNotifier.value =
          userNotifier.value.copyWith(avatarPath: picked.path);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Cancel', 'বাতিল')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(tr('Save', 'সংরক্ষণ')),
          ),
        ],
      ),
    );
    if (result != null &&
        result.isNotEmpty &&
        result != userNotifier.value.name) {
      userNotifier.value = userNotifier.value.copyWith(name: result);
      _toast(tr('Name updated', 'নাম আপডেট হয়েছে'));
    }
  }

  Future<void> _editPassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    bool obscure = true;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(tr('Change password', 'পাসওয়ার্ড পরিবর্তন করুন')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: obscure,
                  decoration: InputDecoration(
                      labelText:
                          tr('Current password', 'বর্তমান পাসওয়ার্ড')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: next,
                  obscureText: obscure,
                  decoration: InputDecoration(
                      labelText: tr('New password', 'নতুন পাসওয়ার্ড')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirm,
                  obscureText: obscure,
                  decoration: InputDecoration(
                      labelText: tr('Confirm new password',
                          'নতুন পাসওয়ার্ড নিশ্চিত করুন')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: !obscure,
                      onChanged: (v) => setSt(() => obscure = !(v ?? false)),
                    ),
                    Text(tr('Show passwords', 'পাসওয়ার্ড দেখান')),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      error!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Cancel', 'বাতিল')),
            ),
            TextButton(
              onPressed: () {
                if (current.text.isEmpty) {
                  setSt(() => error =
                      tr('Enter your current password', 'বর্তমান পাসওয়ার্ড দিন'));
                  return;
                }
                if (next.text.length < 6) {
                  setSt(() => error = tr(
                      'New password must be 6+ characters',
                      'নতুন পাসওয়ার্ড ৬+ অক্ষরের হতে হবে'));
                  return;
                }
                if (next.text != confirm.text) {
                  setSt(() => error =
                      tr('Passwords do not match', 'পাসওয়ার্ড মিলছে না'));
                  return;
                }
                Navigator.pop(ctx);
                _toast(tr('Password updated', 'পাসওয়ার্ড আপডেট হয়েছে'));
              },
              child: Text(tr('Save', 'সংরক্ষণ')),
            ),
          ],
        ),
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
              Text(
                tr('Profile', 'প্রোফাইল'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                tr('Manage your account', 'আপনার অ্যাকাউন্ট পরিচালনা করুন'),
                style: TextStyle(color: muted, fontSize: 14),
              ),
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
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _shadow(context),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
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
                              backgroundImage: _avatarProvider(user),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFB300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Tap photo to change',
                            'পরিবর্তন করতে ফটোতে ট্যাপ করুন'),
                        style: TextStyle(color: muted, fontSize: 12),
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
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shadow(context),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title:
                          Text(tr('Change name', 'নাম পরিবর্তন করুন')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editName,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(
                          tr('Change password', 'পাসওয়ার্ড পরিবর্তন করুন')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editPassword,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: darkModeNotifier,
                      builder: (context, isDark, _) => SwitchListTile(
                        secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode),
                        title: Text(tr('Dark mode', 'ডার্ক মোড')),
                        value: isDark,
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
                        onChanged: (v) => isBanglaNotifier.value = v,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        tr('Log out', 'লগ আউট'),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(tr('Log out?', 'লগ আউট করবেন?')),
                          content: Text(tr(
                              'Are you sure you want to log out?',
                              'আপনি কি নিশ্চিত যে আপনি লগ আউট করতে চান?')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(tr('Cancel', 'বাতিল')),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _toast(tr('Logged out (frontend only)',
                                    'লগ আউট হয়েছে (ফ্রন্টএন্ড)'));
                              },
                              child: Text(
                                tr('Log out', 'লগ আউট'),
                                style: const TextStyle(
                                    color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                itemBuilder: (context, i) =>
                    _TransactionTile(tx: allTransactions[i]),
              ),
            ),
          ),
        );
      },
    );
  }
}