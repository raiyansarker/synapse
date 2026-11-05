import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// DESIGN TOKENS (Strict Monochrome)
// =============================================================================
const Color kBlack = Color(0xFF1A1A1A);
const Color kDarkCardStart = Color(0xFF333333);
const Color kDarkCardEnd = Color(0xFF1A1A1A);
const Color kWhite = Colors.white;
const Color kBgGrey = Color(0xFFF3F4F6);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kRed = Color(0xFFE53935);
const Color kGreen = Color(0xFF10B981);

const String kDefaultAvatar = 'https://i.postimg.cc/3xT2hYKL/profile-avatar.jpg';

// =============================================================================
// STATE & MODELS
// =============================================================================
final ValueNotifier<bool> authNotifier = ValueNotifier(false);
final ValueNotifier<UserState> userNotifier = ValueNotifier(const UserState(name: 'Bardia', email: ''));
final LocalAuthentication _localAuth = LocalAuthentication();
String _mockUserPassword = 'password';

// --- DYNAMIC DATA NOTIFIERS ---
final ValueNotifier<List<Tx>> transactionsNotifier = ValueNotifier([]);
final ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);

// --- LOAN STATE ---
final ValueNotifier<double> loanNotifier = ValueNotifier(0.0);
final ValueNotifier<DateTime?> loanDueDateNotifier = ValueNotifier(null);

// --- SUBSCRIPTION & PRO STATE ---
final ValueNotifier<bool> isProNotifier = ValueNotifier(false);
final ValueNotifier<List<String>> purchasedSubsNotifier = ValueNotifier([]);

// --- SAVINGS STATE ---
final ValueNotifier<double> savingsBalanceNotifier = ValueNotifier(0.0);
final ValueNotifier<bool> savingsEnabledNotifier = ValueNotifier(false);
final ValueNotifier<DateTime?> savingsStartDateNotifier = ValueNotifier(null);
final ValueNotifier<DateTime?> lastSavingsCutNotifier = ValueNotifier(null);
final ValueNotifier<bool> missedSavingsNotifier = ValueNotifier(false);

class UserState {
  final String name;
  final String email;
  final String? avatarPath;
  final bool isBiometricEnabled;

  const UserState({required this.name, required this.email, this.avatarPath, this.isBiometricEnabled = false});

  UserState copyWith({String? name, String? email, String? avatarPath, bool? isBiometricEnabled}) =>
      UserState(
        name: name ?? this.name,
        email: email ?? this.email,
        avatarPath: avatarPath ?? this.avatarPath,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      );
}

class Tx {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String time;
  final IconData icon;
  final bool isIncome;

  const Tx({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.icon,
    this.isIncome = false,
  });
}

class SubModel {
  final String name;
  final IconData icon;
  final double price;
  final String emailLabel;
  final List<String> benefits;

  const SubModel(this.name, this.icon, this.price, this.emailLabel, this.benefits);
}

final List<SubModel> availableSubs = [
  const SubModel('Synapse Pro', Icons.stars, 500.0, 'Synapse Account Email', [
    '5% Cashback on all bills',
    'Higher loan limit (৳5,000)',
    'Priority customer support',
    'Exclusive partner discounts'
  ]),
  const SubModel('Netflix', Icons.movie_filter, 650.0, 'Netflix Account Email', [
    'Unlimited movies and TV shows',
    'Ad-free streaming',
    'Watch on any device',
    'Download and watch offline'
  ]),
  const SubModel('Spotify', Icons.music_note, 199.0, 'Spotify Username', [
    'Listen to music ad-free',
    'Play any song, any time',
    'Offline mode',
    'High-quality audio'
  ]),
  const SubModel('Claude Pro', Icons.smart_toy, 1600.0, 'Claude Account Email', [
    '5x more usage than free plan',
    'Access to latest models',
    'Priority access during high traffic',
    'Early access to new features'
  ]),
  const SubModel('Google One', Icons.cloud, 150.0, 'Google Email', [
    '100 GB of cloud storage',
    'Share with up to 5 family members',
    'Extra member benefits',
    '24/7 expert support'
  ]),
  const SubModel('Crunchyroll', Icons.play_circle_fill, 400.0, 'Crunchyroll Email', [
    'Ad-free anime streaming',
    'New episodes one hour after Japan',
    'Access to manga library',
    'Offline viewing'
  ]),
];

class AdItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const AdItem({required this.title, required this.subtitle, required this.icon, required this.onTap});
}

// =============================================================================
// BACKEND INTEGRATION HELPERS
// =============================================================================
void _addTransaction(Tx tx) {
  transactionsNotifier.value = [tx, ...transactionsNotifier.value];
  if (tx.isIncome) {
    balanceNotifier.value += tx.amount;
  } else {
    balanceNotifier.value -= tx.amount.abs();
  }
}

void _checkLoanAutoDeduction() {
  final dueDate = loanDueDateNotifier.value;
  final loanAmt = loanNotifier.value;

  if (loanAmt > 0 && dueDate != null && DateTime.now().isAfter(dueDate)) {
    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Auto Loan Deduction',
      subtitle: 'Loan Repayment',
      amount: -loanAmt,
      time: 'Just now',
      icon: Icons.warning_amber_rounded,
      isIncome: false,
    ));
    loanNotifier.value = 0;
    loanDueDateNotifier.value = null;
  }
}

void _checkSavingsAutoCut() {
  if (!savingsEnabledNotifier.value) return;
  final lastCut = lastSavingsCutNotifier.value;
  if (lastCut == null) return;

  final daysSinceLastCut = DateTime.now().difference(lastCut).inDays;
  
  if (daysSinceLastCut >= 30) {
    double amtToCut = missedSavingsNotifier.value ? 210.0 : 100.0;
    
    if (balanceNotifier.value >= amtToCut) {
      _addTransaction(Tx(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Savings Auto-Save',
        subtitle: 'Monthly Deposit',
        amount: -amtToCut,
        time: 'Just now',
        icon: Icons.savings,
        isIncome: false,
      ));
      savingsBalanceNotifier.value += amtToCut;
      missedSavingsNotifier.value = false;
    } else {
      missedSavingsNotifier.value = true;
    }
    lastSavingsCutNotifier.value = DateTime.now();
  }
}

// =============================================================================
// HELPERS
// =============================================================================
String formatMoney(double v) {
  final abs = v.abs().toStringAsFixed(2);
  final parts = abs.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '৳${v < 0 ? '-' : ''}${buf.toString()}.${parts[1]}';
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

ImageProvider _avatarProvider(UserState u) => u.avatarPath != null
    ? FileImage(File(u.avatarPath!))
    : const NetworkImage(kDefaultAvatar) as ImageProvider;

Future<bool> _authenticateBiometrics(BuildContext context) async {
  try {
    final withBio = await _localAuth.canCheckBiometrics;
    final supported = withBio || await _localAuth.isDeviceSupported();
    if (!supported) return true; 

    return await _localAuth.authenticate(
      localizedReason: 'Authenticate to proceed',
      options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  } catch (_) {
    return false;
  }
}

Future<bool> _showPasswordDialog(BuildContext context) async {
  final passCtrl = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Security Check'),
      content: RepaintBoundary(
        child: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password (try: password)',
            hintStyle: TextStyle(color: kTextGrey),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (passCtrl.text == _mockUserPassword) {
              Navigator.pop(ctx, true);
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Incorrect password')));
            }
          },
          child: const Text('Unlock'),
        ),
      ],
    ),
  );
  passCtrl.dispose();
  return result ?? false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  userNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    final u = userNotifier.value;
    await p.setString('user_name', u.name);
    await p.setString('user_email', u.email);
    await p.setBool('biometric_enabled', u.isBiometricEnabled);
    if (u.avatarPath != null) await p.setString('user_avatar', u.avatarPath!);
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBgGrey,
        colorScheme: const ColorScheme.light(primary: kBlack, surface: kWhite),
      ),
      home: const AuthWrapper(),
    );
  }
}

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
      final email = prefs.getString('user_email');
      final isBioEnabled = prefs.getBool('biometric_enabled') ?? false;
      final avatar = prefs.getString('user_avatar');

      if (name != null && email != null && name != 'User') {
        userNotifier.value = UserState(name: name, email: email, isBiometricEnabled: isBioEnabled, avatarPath: avatar);
        if (isBioEnabled) {
          final success = await _localAuth.authenticate(
            localizedReason: 'Quick Login',
            options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
          );
          if (success) authNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLoanAutoDeduction();
        _checkSavingsAutoCut();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kBlack)));
    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (context, _, __) => authNotifier.value ? const HomePage() : const LoginPage(),
    );
  }
}

// =============================================================================
// LOGIN PAGE
// =============================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid credentials')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _mockUserPassword = password;
    final current = userNotifier.value;
    final derivedName = email.split('@').first;
    
    userNotifier.value = UserState(
      name: derivedName.isNotEmpty ? derivedName : 'Bardia',
      email: email,
      isBiometricEnabled: current.isBiometricEnabled,
      avatarPath: current.avatarPath,
    );
    authNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  height: 90, width: 90,
                  decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.account_balance, color: kWhite, size: 45),
                ),
                const SizedBox(height: 24),
                const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBlack)),
                const SizedBox(height: 8),
                const Text('Sign in to continue', style: TextStyle(color: kTextGrey)),
                const SizedBox(height: 40),
                _LoginField(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _LoginField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline, obscure: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlack,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                      : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
  final bool obscure;

  const _LoginField({required this.controller, required this.hint, required this.icon, this.keyboardType, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Icon(icon, color: kTextGrey),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscure,
                style: const TextStyle(color: kBlack, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: kTextGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HOME PAGE
// =============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  late double _screenHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight = MediaQuery.of(context).size.height;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background Content
            Positioned.fill(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: ValueListenableBuilder<UserState>(
                      valueListenable: userNotifier,
                      builder: (context, user, _) => Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundImage: _avatarProvider(user)),
                          const SizedBox(width: 12),
                          Text(
                            'Hello, ${user.name.isEmpty ? "Bardia" : user.name}!',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: kWhite, shape: BoxShape.circle),
                              child: const Icon(Icons.settings, size: 20, color: kBlack),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // CENTERED Balance Display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Total Balance', 
                            style: TextStyle(color: kTextGrey, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<double>(
                            valueListenable: balanceNotifier,
                            builder: (context, balance, _) => Text(
                              formatMoney(balance), 
                              style: TextStyle(
                                color: balance < 0 ? kRed : kBlack, 
                                fontSize: 42, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: -1
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.north_east,
                            label: 'Send',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPage())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.south_west,
                            label: 'Receive',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePage())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.more_horiz,
                            label: 'More',
                            onTap: () => _showMoreMenu(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // DYNAMIC AD CAROUSEL
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AdCarousel(),
                  ),
                  
                  const Spacer(), 
                ],
              ),
            ),

            // Swipeable Bottom Sheet
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.45,
              minChildSize: 0.45,
              maxChildSize: 1.0,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          final delta = details.primaryDelta ?? 0.0;
                          final newSize = _sheetController.size - (delta / _screenHeight);
                          _sheetController.jumpTo(newSize.clamp(0.45, 1.0));
                        },
                        onVerticalDragEnd: (details) {
                          if (_sheetController.size > 0.7) {
                            _sheetController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          } else {
                            _sheetController.animateTo(0.45, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent, 
                          child: Center(
                            child: Container(
                              width: 40, height: 4, 
                              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))
                            ),
                          ),
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Text('Latest Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: ValueListenableBuilder<List<Tx>>(
                          valueListenable: transactionsNotifier,
                          builder: (context, txs, _) {
                            if (txs.isEmpty) {
                              return const Center(
                                child: Text('No recent transactions', style: TextStyle(color: kTextGrey)),
                              );
                            }
                            return ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              itemCount: txs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final tx = txs[i];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: kWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(color: kBgGrey, shape: BoxShape.circle),
                                        child: Icon(tx.icon, color: kBlack, size: 20),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kBlack)),
                                            const SizedBox(height: 4),
                                            Text(tx.time, style: const TextStyle(color: kTextGrey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${tx.isIncome ? '+' : ''}${formatMoney(tx.amount)}', 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tx.isIncome ? kGreen : kBlack)
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        ),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text('More Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.savings, color: kBlack),
              title: const Text('Savings / Auto-Save', style: TextStyle(color: kBlack)),
              onTap: () { 
                Navigator.pop(ctx); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsPage())); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments, color: kBlack),
              title: const Text('Loan / Advance', style: TextStyle(color: kBlack)),
              onTap: () { 
                Navigator.pop(ctx); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanPage())); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions, color: kBlack),
              title: const Text('Subscriptions', style: TextStyle(color: kBlack)),
              onTap: () { 
                Navigator.pop(ctx); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage())); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: kBlack),
              title: const Text('Pay Bill', style: TextStyle(color: kBlack)),
              onTap: () { Navigator.pop(ctx); _showBillMenu(context); },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: kBlack),
              title: const Text('Education Payment', style: TextStyle(color: kBlack)),
              onTap: () { Navigator.pop(ctx); _showEducationMenu(context); },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: kBlack),
              title: const Text('Shopping Payment', style: TextStyle(color: kBlack)),
              onTap: () { 
                Navigator.pop(ctx); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerPage())); 
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBillMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text('Select Biller', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
            const SizedBox(height: 10),
            ListTile(title: const Text('DPDC'), onTap: () { Navigator.pop(ctx); _goToBillPayment(context, 'DPDC', 'Meter Number'); }),
            ListTile(title: const Text('DESCO'), onTap: () { Navigator.pop(ctx); _goToBillPayment(context, 'DESCO', 'Meter Number'); }),
            ListTile(title: const Text('Dot Internet'), onTap: () { Navigator.pop(ctx); _goToBillPayment(context, 'Dot Internet', 'Customer Number'); }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _goToBillPayment(BuildContext context, String billerName, String idLabel) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BillPaymentPage(billerName: billerName, idLabel: idLabel)));
  }

  void _showEducationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text('Select Institution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
            const SizedBox(height: 10),
            ListTile(title: const Text('Shamsul Hoque Khan School and College'), onTap: () { Navigator.pop(ctx); _goToEducationPayment(context, 'Shamsul Hoque Khan School', false); }),
            ListTile(title: const Text('Dhaka City College'), onTap: () { Navigator.pop(ctx); _goToEducationPayment(context, 'Dhaka City College', false); }),
            ListTile(title: const Text('Dhaka College'), onTap: () { Navigator.pop(ctx); _goToEducationPayment(context, 'Dhaka College', false); }),
            ListTile(title: const Text('Daffodil International University'), onTap: () { Navigator.pop(ctx); _goToEducationPayment(context, 'Daffodil International University', true); }),
            ListTile(title: const Text('South-East University'), onTap: () { Navigator.pop(ctx); _goToEducationPayment(context, 'South-East University', true); }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _goToEducationPayment(BuildContext context, String institutionName, bool isUniversity) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EducationPaymentPage(institutionName: institutionName, isUniversity: isUniversity)));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: kBlack),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBlack)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SAVINGS PAGE
// =============================================================================
class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});
  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _isLoading = false;

  Future<void> _withdraw() async {
    final startDate = savingsStartDateNotifier.value;
    if (startDate == null) return;

    if (DateTime.now().difference(startDate).inDays < 365) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('You can only withdraw after 1 year.'),
      ));
      return;
    }

    if (savingsBalanceNotifier.value <= 0) return;

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final amt = savingsBalanceNotifier.value;
    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Savings Withdrawn',
      subtitle: 'To Main Balance',
      amount: amt,
      time: 'Just now',
      icon: Icons.savings,
      isIncome: true,
    ));

    savingsBalanceNotifier.value = 0;
    savingsEnabledNotifier.value = false;
    savingsStartDateNotifier.value = null;
    lastSavingsCutNotifier.value = null;
    missedSavingsNotifier.value = false;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kGreen, 
      content: Text('Successfully withdrawn ${formatMoney(amt)}!')
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Savings', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                  child: const Icon(Icons.savings, color: kWhite, size: 60),
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: Text('Total Savings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack))),
              const SizedBox(height: 8),
              Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: savingsBalanceNotifier,
                  builder: (context, balance, _) => Text(
                    formatMoney(balance), 
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kGreen),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: savingsEnabledNotifier,
                      builder: (context, enabled, _) => SwitchListTile(
                        secondary: const Icon(Icons.autorenew, color: kBlack),
                        title: const Text('Auto-Save 100 TK/month', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Automatically cuts 100 TK every 30 days.'),
                        value: enabled,
                        activeThumbColor: kBlack,
                        onChanged: (val) {
                          if (!val) {
                            // Trying to turn OFF
                            final startDate = savingsStartDateNotifier.value;
                            if (startDate != null && DateTime.now().difference(startDate).inDays < 365) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                backgroundColor: kRed,
                                content: Text('Auto-save is locked for 1 year. You cannot turn it off.'),
                              ));
                              return;
                            }
                          }
                          
                          savingsEnabledNotifier.value = val;
                          if (val) {
                            savingsStartDateNotifier.value = DateTime.now();
                            lastSavingsCutNotifier.value = DateTime.now();
                            missedSavingsNotifier.value = false;
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ValueListenableBuilder<bool>(
                      valueListenable: missedSavingsNotifier,
                      builder: (context, missed, _) {
                        if (!missed) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Warning: You missed a payment! Next cut will be 210 TK (100 double + 10 penalty).',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // MOVED ORANGE WARNING HERE (Replaces blue)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Warning: Turning on Auto-Save locks your deposited savings for 1 year. You cannot turn it off or withdraw until then.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _withdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                    : const Text('Withdraw Savings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DYNAMIC AD CAROUSEL
// =============================================================================
class AdCarousel extends StatefulWidget {
  const AdCarousel({super.key});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<AdItem> _ads = [];

  @override
  void initState() {
    super.initState();
    _generateAds();
    
    isProNotifier.addListener(_onAdsChanged);
    purchasedSubsNotifier.addListener(_onAdsChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    isProNotifier.removeListener(_onAdsChanged);
    purchasedSubsNotifier.removeListener(_onAdsChanged);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onAdsChanged() {
    if (!mounted) return;
    setState(() {
      _generateAds();
    });
    _startAutoScroll();
  }

  void _generateAds() {
    List<AdItem> ads = [];

    if (!isProNotifier.value) {
      ads.add(AdItem(
        title: 'Upgrade to Synapse Pro',
        subtitle: 'Get 5% cashback and higher loan limits.',
        icon: Icons.stars, 
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePage())),
      ));
    }

    for (var sub in availableSubs) {
      if (sub.name != 'Synapse Pro' && !purchasedSubsNotifier.value.contains(sub.name)) {
        ads.add(AdItem(
          title: 'Get ${sub.name}',
          subtitle: 'Subscribe for only ${formatMoney(sub.price)}/month.',
          icon: sub.icon,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionBenefitsPage(sub: sub))),
        ));
      }
    }

    ads.add(AdItem(
      title: 'Prothom Alo',
      subtitle: 'Read the latest news from Bangladesh.',
      icon: Icons.newspaper,
      onTap: () => _openUrl('https://www.prothomalo.com/'),
    ));

    _ads = ads;
    if (_currentPage >= _ads.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_ads.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      
      int nextPage = _currentPage + 1;
      if (nextPage >= _ads.length) nextPage = 0;
      
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _ads.length,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return GestureDetector(
            onTap: ad.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kDarkCardStart, kBlack],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(ad.icon, color: kWhite, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ad.title, 
                          style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ad.subtitle, 
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kWhite, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// LOAN PAGE
// =============================================================================
class LoanPage extends StatefulWidget {
  const LoanPage({super.key});
  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _takeLoan() async {
    final amt = double.tryParse(_amountController.text) ?? 0;
    final maxLimit = isProNotifier.value ? 5000.0 : 1000.0;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (amt > maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: kRed,
        content: Text('Amount exceeds your limit of ${formatMoney(maxLimit)}'),
      ));
      return;
    }
    if (loanNotifier.value > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('You must clear your previous loan first.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    loanNotifier.value = amt;
    loanDueDateNotifier.value = DateTime.now().add(const Duration(days: 30));

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Loan Disbursed',
      subtitle: 'Advance',
      amount: amt,
      time: 'Just now',
      icon: Icons.payments,
      isIncome: true,
    ));

    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kGreen, 
      content: Text('Loan of ${formatMoney(amt)} disbursed successfully!')
    ));
  }

  Future<void> _repayLoan() async {
    final amt = loanNotifier.value;
    if (amt <= 0) return;

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Loan Repayment',
      subtitle: 'Cleared',
      amount: -amt,
      time: 'Just now',
      icon: Icons.check_circle,
      isIncome: false,
    ));

    loanNotifier.value = 0;
    loanDueDateNotifier.value = null;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kGreen, 
      content: Text('Loan fully repaid!')
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Loan / Advance', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.payments, size: 60, color: kBlack),
              const SizedBox(height: 24),
              const Text('Take a Loan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text('Get instant funds. Repay within 30 days.', style: TextStyle(color: kTextGrey)),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kBlack)),
                    ValueListenableBuilder<bool>(
                      valueListenable: isProNotifier,
                      builder: (context, isPro, _) => Text(
                        isPro ? '৳5,000' : '৳1,000',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGreen),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              ValueListenableBuilder<double>(
                valueListenable: loanNotifier,
                builder: (context, activeLoan, _) {
                  if (activeLoan > 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding Loan', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(formatMoney(activeLoan), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kBlack)),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<DateTime?>(
                                valueListenable: loanDueDateNotifier,
                                builder: (context, dueDate, _) => Text(
                                  'Due Date: ${dueDate != null ? formatDate(dueDate) : "N/A"}',
                                  style: const TextStyle(color: kTextGrey, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('You must repay your current loan before taking a new one.', style: TextStyle(color: kTextGrey, fontSize: 12)),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _repayLoan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlack,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                              : const Text('Repay Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Enter Amount (৳)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, right: 12),
                                  child: Text('৳', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: kTextGrey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your loan will be due in 30 days. If unpaid, the amount will be automatically deducted, potentially resulting in a negative balance.',
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _takeLoan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlack,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                              : const Text('Take Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  }
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// UPGRADE PAGE
// =============================================================================
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});
  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  bool _isLoading = false;

  Future<void> _processUpgrade() async {
    if (500.0 > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please take a loan or receive money first.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    isProNotifier.value = true;
    purchasedSubsNotifier.value = [...purchasedSubsNotifier.value, 'Synapse Pro'];

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Synapse Pro Upgrade',
      subtitle: 'Subscription',
      amount: -500.0,
      time: 'Just now',
      icon: Icons.stars, 
      isIncome: false,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Synapse Pro', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                child: const Icon(Icons.stars, color: kWhite, size: 60), 
              ),
              const SizedBox(height: 24),
              const Text('Upgrade to Synapse Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text('Unlock premium features and get more out of your wallet.', textAlign: TextAlign.center, style: TextStyle(color: kTextGrey, fontSize: 16)),
              
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.check_circle, '5% Cashback on all bills'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.check_circle, 'Higher loan limit (up to ৳5,000)'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.check_circle, 'Priority customer support'),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              const Text('Monthly Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              const Text('৳500.00 / month', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                    : const Text('Subscribe for ৳500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kBlack, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: kBlack, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// =============================================================================
// SUBSCRIPTION PAGES
// =============================================================================
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Subscriptions', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: availableSubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final sub = availableSubs[i];
          
          if (sub.name == 'Synapse Pro') {
            return ValueListenableBuilder<bool>(
              valueListenable: isProNotifier,
              builder: (context, isPro, _) {
                if (isPro) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kBlack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: kWhite, size: 24),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text('Synapse Pro Active', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const Icon(Icons.check_circle, color: kGreen, size: 24),
                      ],
                    ),
                  );
                }
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePage())),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBlack.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stars, color: kBlack, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Synapse Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlack)),
                              SizedBox(height: 4),
                              Text('Get 5% cashback and higher limits', style: TextStyle(color: kTextGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(sub.price),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlack),
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          }

          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionBenefitsPage(sub: sub))),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBlack.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(sub.icon, color: kBlack, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlack)),
                        const SizedBox(height: 4),
                        const Text('Monthly subscription', style: TextStyle(color: kTextGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(sub.price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlack),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// SUBSCRIPTION BENEFITS PAGE
// =============================================================================
class SubscriptionBenefitsPage extends StatelessWidget {
  final SubModel sub;
  const SubscriptionBenefitsPage({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: Text(sub.name, style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                child: Icon(sub.icon, color: kWhite, size: 60),
              ),
              const SizedBox(height: 24),
              Text('Get ${sub.name}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              Text('See what is included in your subscription.', textAlign: TextAlign.center, style: const TextStyle(color: kTextGrey, fontSize: 16)),
              
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sub.benefits.map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: kBlack, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(benefit, style: const TextStyle(color: kBlack, fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40),
              const Text('Monthly Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              Text('${formatMoney(sub.price)} / month', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionCheckoutPage(sub: sub))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Proceed to Pay ${formatMoney(sub.price)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionCheckoutPage extends StatefulWidget {
  final SubModel sub;
  const SubscriptionCheckoutPage({super.key, required this.sub});

  @override
  State<SubscriptionCheckoutPage> createState() => _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  final _accountIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountIdController.dispose();
    super.dispose();
  }

  Future<void> _processPurchase() async {
    final accountId = _accountIdController.text.trim();
    if (accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your ${widget.sub.emailLabel}')));
      return;
    }

    if (widget.sub.price > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please take a loan or receive money.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    purchasedSubsNotifier.value = [...purchasedSubsNotifier.value, widget.sub.name];

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${widget.sub.name} Subscription',
      subtitle: 'For $accountId',
      amount: -widget.sub.price,
      time: 'Just now',
      icon: widget.sub.icon,
      isIncome: false,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: Text('Buy ${widget.sub.name}', style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: kWhite, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
                  child: Icon(widget.sub.icon, size: 64, color: kBlack),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Account Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 8),
              Text('Enter the account information needed to activate your ${widget.sub.name} subscription.', style: const TextStyle(color: kTextGrey, fontSize: 14)),
              
              const SizedBox(height: 24),
              RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 12),
                        child: Icon(Icons.person, color: kTextGrey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _accountIdController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16, color: kBlack),
                          decoration: InputDecoration(
                            hintText: widget.sub.emailLabel,
                            hintStyle: const TextStyle(color: kTextGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subscription Fee', style: TextStyle(color: kTextGrey)),
                        Text(formatMoney(widget.sub.price), style: const TextStyle(fontWeight: FontWeight.bold, color: kBlack)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: kBlack)),
                        Text(formatMoney(widget.sub.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBlack)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 18),
                          const SizedBox(width: 8),
                          Text('Pay ${formatMoney(widget.sub.price)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
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

// =============================================================================
// SEND PAGE
// =============================================================================
class SendPage extends StatefulWidget {
  const SendPage({super.key});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final _codeController = TextEditingController();
  String _amount = '0';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    FocusScope.of(context).unfocus(); 
    
    setState(() {
      if (key == 'back') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
          _amount += key;
        }
      }
    });
  }

  Future<void> _processTransfer() async {
    final code = _codeController.text.trim();
    final amt = double.tryParse(_amount) ?? 0;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a recipient code')));
      return;
    }

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (amt > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please receive money first.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Sent to $code',
      subtitle: 'Transfer',
      amount: -amt,
      time: 'Just now',
      icon: Icons.north_east,
      isIncome: false,
    ));
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Send Money', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: kBlack),
            onPressed: () async {
              final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerPage()));
              if (result != null) {
                _codeController.text = result;
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: kBgGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20, right: 12),
                      child: Icon(Icons.person_outline, color: kBlack),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        style: const TextStyle(fontSize: 16, color: kBlack, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Enter recipient code',
                          hintStyle: TextStyle(color: kTextGrey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          Text('৳$_amount', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: kBlack)),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: balanceNotifier,
            builder: (context, balance, _) => Text('Available: ${formatMoney(balance)}', style: const TextStyle(color: kTextGrey)),
          ),
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                _buildKeyRow(['4', '5', '6']),
                _buildKeyRow(['7', '8', '9']),
                _buildKeyRow(['.', '0', 'back']),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlack,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 18),
                    SizedBox(width: 8),
                    Text('Confirm Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        return InkWell(
          onTap: () => _onKeyPress(k),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70, height: 70,
            alignment: Alignment.center,
            child: k == 'back'
                ? const Icon(Icons.backspace_outlined, color: kBlack)
                : Text(k, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: kBlack)),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// RECEIVE PAGE
// =============================================================================
class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});
  static const String _paymentCode = '4015 5587 9985 3279';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Receive Money', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(24)),
                child: QrImageView(
                  data: 'wallet://pay?code=$_paymentCode',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: kWhite,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: kBlack),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: kBlack),
                ),
              ),
              const SizedBox(height: 30),
              const Text('Scan to pay me', style: TextStyle(color: kTextGrey, fontSize: 16)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: const Text(_paymentCode, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: kBlack)),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _paymentCode));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack, foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// =============================================================================
// QR SCANNER
// =============================================================================
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhite),
        title: const Text('Scan QR', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
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
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: kWhite, width: 4), borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const Positioned(
            bottom: 60, left: 0, right: 0,
            child: Center(child: Text('Align QR within the frame', style: TextStyle(color: kWhite, fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUCCESS PAGE
// =============================================================================
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 50, color: kWhite),
              ),
              const SizedBox(height: 24),
              const Text('Transaction Successful', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlack)),
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const _DetailRow(label: 'Status', value: 'Completed', valueColor: kGreen),
                    const Divider(height: 24),
                    _DetailRow(label: 'Reference', value: 'REF${now.millisecondsSinceEpoch.toString().substring(7)}'),
                    const Divider(height: 24),
                    _DetailRow(label: 'Date', value: '${now.day}/${now.month}/${now.year}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack, foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? kBlack)),
      ],
    );
  }
}

// =============================================================================
// BILL PAYMENT PAGE
// =============================================================================
class BillPaymentPage extends StatefulWidget {
  final String billerName;
  final String idLabel;

  const BillPaymentPage({super.key, required this.billerName, required this.idLabel});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _idController = TextEditingController();
  bool _isLoading = false;
  double? _dueAmount;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _checkBill() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter ${widget.idLabel}')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _dueAmount = (id.hashCode % 500) + 45.50; 
    });
  }

  Future<void> _processPayment() async {
    if (_dueAmount! > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please take a loan or receive money.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.billerName,
      subtitle: 'Bill Payment',
      amount: -_dueAmount!,
      time: 'Just now',
      icon: Icons.receipt_long,
      isIncome: false,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlack), 
          onPressed: () {
            if (_dueAmount != null) {
              setState(() => _dueAmount = null);
            } else {
              Navigator.pop(context);
            }
          }
        ),
        title: Text(widget.billerName, style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _dueAmount == null ? _buildInputScreen() : _buildBillScreen(),
        ),
      ),
    );
  }

  Widget _buildInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.receipt_long, size: 60, color: kBlack),
        const SizedBox(height: 24),
        Text('Pay ${widget.billerName} Bill', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBlack)),
        const SizedBox(height: 8),
        Text('Enter your ${widget.idLabel} to fetch the current due amount.', style: const TextStyle(color: kTextGrey)),
        const SizedBox(height: 40),
        
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.numbers, color: kTextGrey),
                ),
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, color: kBlack),
                    decoration: InputDecoration(
                      hintText: widget.idLabel,
                      hintStyle: const TextStyle(color: kTextGrey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkBill,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
              : const Text('Check Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBillScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, color: kWhite, size: 40),
              const SizedBox(height: 16),
              const Text('Total Due', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('৳${_dueAmount!.toStringAsFixed(2)}', style: const TextStyle(color: kWhite, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildDetailRow('Biller', widget.billerName),
              const Divider(height: 24),
              _buildDetailRow(widget.idLabel, _idController.text),
              const Divider(height: 24),
              _buildDetailRow('Status', 'Unpaid', valueColor: Colors.orange),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 18),
                const SizedBox(width: 8),
                Text('Pay ৳${_dueAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? kBlack)),
      ],
    );
  }
}

// =============================================================================
// EDUCATION PAYMENT PAGE
// =============================================================================
class EducationPaymentPage extends StatefulWidget {
  final String institutionName;
  final bool isUniversity;

  const EducationPaymentPage({super.key, required this.institutionName, required this.isUniversity});

  @override
  State<EducationPaymentPage> createState() => _EducationPaymentPageState();
}

class _EducationPaymentPageState extends State<EducationPaymentPage> {
  final _idController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _studentName;
  String? _studentDepartment;

  final List<String> _bdNames = [
    "Tanvir Hossain", "Sajid Hasan", "Raiyan Sarker", "Mehedi Hasan", 
    "Rafiul Islam", "Fahim Shahriar", "Nusrat Jahan", "Tasnim Rahman", 
    "Arif Chowdhury", "Sumaiya Akter", "Mahmudul Hasan", "Sadia Islam"
  ];

  final List<String> _departments = [
    "Computer Science & Engineering (CSE)", 
    "Bachelor of Business Administration (BBA)", 
    "Electrical & Electronic Engineering (EEE)", 
    "English Literature", 
    "Pharmacy", 
    "Architecture"
  ];

  @override
  void dispose() {
    _idController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _findStudent() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Student ID')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    
    final nameIndex = (id.hashCode % _bdNames.length).abs();
    
    setState(() {
      _isLoading = false;
      _studentName = _bdNames[nameIndex];
      if (widget.isUniversity) {
        final deptIndex = (id.hashCode % _departments.length).abs();
        _studentDepartment = _departments[deptIndex];
      }
    });
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (amount > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kRed,
        content: Text('Insufficient balance. Please take a loan or receive money.'),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics(context);
      if (!authorized) authorized = await _showPasswordDialog(context);
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.institutionName,
      subtitle: 'Education Payment',
      amount: -amount,
      time: 'Just now',
      icon: Icons.school,
      isIncome: false,
    ));

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlack), 
          onPressed: () {
            if (_studentName != null) {
              setState(() {
                _studentName = null;
                _studentDepartment = null;
              });
            } else {
              Navigator.pop(context);
            }
          }
        ),
        title: const Text('Education Payment', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _studentName == null ? _buildInputScreen() : _buildStudentInfoScreen(),
        ),
      ),
    );
  }

  Widget _buildInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.school, size: 60, color: kBlack),
        const SizedBox(height: 24),
        Text(widget.institutionName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlack)),
        const SizedBox(height: 8),
        const Text('Enter the Student ID to fetch details.', style: TextStyle(color: kTextGrey)),
        const SizedBox(height: 40),
        
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.badge_outlined, color: kTextGrey),
                ),
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontSize: 16, color: kBlack),
                    decoration: const InputDecoration(
                      hintText: 'Student ID',
                      hintStyle: TextStyle(color: kTextGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _findStudent,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
              : const Text('Find Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfoScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.person, size: 60, color: kBlack),
        const SizedBox(height: 24),
        const Text('Student Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlack)),
        const SizedBox(height: 8),
        const Text('Enter the amount you want to pay for this student.', style: TextStyle(color: kTextGrey)),
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildDetailRow('Institution', widget.institutionName),
              const Divider(height: 24),
              _buildDetailRow('Student Name', _studentName!),
              if (widget.isUniversity) ...[
                const Divider(height: 24),
                _buildDetailRow('Department', _studentDepartment!),
              ],
              const Divider(height: 24),
              _buildDetailRow('Student ID', _idController.text),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        const Text('Amount to Pay (৳)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBlack)),
        const SizedBox(height: 10),
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Text('৳', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack)),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBlack),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: kTextGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlack,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 18),
                SizedBox(width: 8),
                Text('Proceed to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 14)),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? kBlack),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PROFILE PAGE
// =============================================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) userNotifier.value = userNotifier.value.copyWith(avatarPath: picked.path);
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: userNotifier.value.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change name'),
        content: RepaintBoundary(
          child: TextField(
            controller: ctrl, 
            decoration: const InputDecoration(
              labelText: 'Name',
              hintStyle: TextStyle(color: kTextGrey),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty && result != userNotifier.value.name) {
      userNotifier.value = userNotifier.value.copyWith(name: result);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final auth = await _authenticateBiometrics(context);
      if (auth) userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: true);
    } else {
      userNotifier.value = userNotifier.value.copyWith(isBiometricEnabled: false);
    }
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); authNotifier.value = false; },
            child: const Text('Log out', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      appBar: AppBar(
        backgroundColor: kBgGrey,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context)),
        title: const Text('Settings', style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<UserState>(
        valueListenable: userNotifier,
        builder: (context, user, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: _avatarProvider(user)),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: kBlack, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 18, color: kWhite),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlack))),
            Center(child: Text(user.email, style: const TextStyle(color: kTextGrey))),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: kBlack),
                    title: const Text('Change name', style: TextStyle(color: kBlack)),
                    trailing: const Icon(Icons.chevron_right, color: kTextGrey),
                    onTap: _editName,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: kBlack),
                    title: const Text('Biometric Security', style: TextStyle(color: kBlack)),
                    subtitle: const Text('Required for sending & quick login'),
                    value: user.isBiometricEnabled,
                    activeThumbColor: kBlack,
                    onChanged: _toggleBiometrics,
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: kRed),
                    title: const Text('Log out', style: TextStyle(color: kRed, fontWeight: FontWeight.w500)),
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}