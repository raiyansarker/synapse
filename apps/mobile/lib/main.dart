// Synapse Wallet – main.dart
//
// Single-file Flutter application. Every server touchpoint is marked with
// `// BACKEND:` comments describing the expected endpoint + payload shape.
// All authentication is currently mocked with SharedPreferences + local_auth.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

const Color kGreen = Color(0xFF006A4E);
const Color kRed = Color(0xFFF42A41);
const Color kWhite = Colors.white;
const Color kBlack = Color(0xFF1A1A1A);

const String kDefaultAvatar =
    'https://i.postimg.cc/3xT2hYKL/profile-avatar.jpg';

const String _kUserPasswordKey = 'user_password';
const String _kPaymentCode = '4015 5587 9985 3279';

// Display strings (with BDT symbol) – used in Text widgets.
const String _kLoanLimitBasicText = '৳1,000';
const String _kLoanLimitProText = '৳5,000';

// Numeric values – used in limit calculations.
const double _kLoanLimitBasic = 1000.0;
const double _kLoanLimitPro = 5000.0;
const double _kMonthlySavings = 100.0;
const double _kMonthlySavingsMissed = 210.0;
const double _kProPrice = 500.0;

// =============================================================================
// APP STATE (ValueNotifiers = lightweight reactive store)
// =============================================================================

// BACKEND: Replace each notifier with a stream from your state manager.

final ValueNotifier<bool> authNotifier = ValueNotifier(false);
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
final ValueNotifier<UserState> userNotifier =
    ValueNotifier(const UserState(name: 'Bardia', email: ''));

final ValueNotifier<List<Tx>> transactionsNotifier = ValueNotifier([]);
final ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);

final ValueNotifier<double> loanNotifier = ValueNotifier(0.0);
final ValueNotifier<DateTime?> loanDueDateNotifier = ValueNotifier(null);

final ValueNotifier<bool> isProNotifier = ValueNotifier(false);
final ValueNotifier<List<String>> purchasedSubsNotifier = ValueNotifier([]);

final ValueNotifier<double> savingsBalanceNotifier = ValueNotifier(0.0);
final ValueNotifier<bool> savingsEnabledNotifier = ValueNotifier(false);
final ValueNotifier<DateTime?> savingsStartDateNotifier = ValueNotifier(null);
final ValueNotifier<DateTime?> lastSavingsCutNotifier = ValueNotifier(null);
final ValueNotifier<bool> missedSavingsNotifier = ValueNotifier(false);

final LocalAuthentication _localAuth = LocalAuthentication();

// =============================================================================
// MODELS
// =============================================================================

/// Snapshot of the signed-in user. Mirrors `GET /api/v1/me` response.
class UserState {
  final String name;
  final String email;
  final String? avatarPath;
  final bool isBiometricEnabled;

  const UserState({
    required this.name,
    required this.email,
    this.avatarPath,
    this.isBiometricEnabled = false,
  });

  UserState copyWith({
    String? name,
    String? email,
    String? avatarPath,
    bool? isBiometricEnabled,
  }) =>
      UserState(
        name: name ?? this.name,
        email: email ?? this.email,
        avatarPath: avatarPath ?? this.avatarPath,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      );
}

/// Transaction record. Backend should populate `id` with UUID.
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

/// Third-party subscription product. `price` is monthly BDT.
class SubModel {
  final String name;
  final IconData icon;
  final double price;
  final String emailLabel;
  final List<String> benefits;

  const SubModel(
    this.name,
    this.icon,
    this.price,
    this.emailLabel,
    this.benefits,
  );
}

/// Rotating promotional card. Backend can serve via `GET /api/v1/ads`.
class AdItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const AdItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

// =============================================================================
// STATIC DATA
// =============================================================================

// BACKEND: Serve from `GET /api/v1/subscriptions` catalog.
final List<SubModel> availableSubs = [
  const SubModel('Synapse Pro', Icons.stars_outlined, 500.0,
      'Synapse Account Email', [
    '5% Cashback on all bills',
    'Higher loan limit (৳5,000)',
    'Priority customer support',
    'Exclusive partner discounts',
  ]),
  const SubModel('Netflix', Icons.movie_outlined, 650.0,
      'Netflix Account Email', [
    'Unlimited movies and TV shows',
    'Ad-free streaming',
    'Watch on any device',
    'Download and watch offline',
  ]),
  const SubModel('Spotify', Icons.music_note_outlined, 199.0,
      'Spotify Username', [
    'Listen to music ad-free',
    'Play any song, any time',
    'Offline mode',
    'High-quality audio',
  ]),
  const SubModel('Claude Pro', Icons.smart_toy_outlined, 1600.0,
      'Claude Account Email', [
    '5x more usage than free plan',
    'Access to latest models',
    'Priority access during high traffic',
    'Early access to new features',
  ]),
  const SubModel('Google One', Icons.cloud_outlined, 150.0, 'Google Email', [
    '100 GB of cloud storage',
    'Share with up to 5 family members',
    'Extra member benefits',
    '24/7 expert support',
  ]),
  const SubModel('Crunchyroll', Icons.play_circle_outline, 400.0,
      'Crunchyroll Email', [
    'Ad-free anime streaming',
    'New episodes one hour after Japan',
    'Access to manga library',
    'Offline viewing',
  ]),
];

// =============================================================================
// UTILITIES
// =============================================================================

/// Format `1234.56` → `৳1,234.56` (BDT with thousands separator).
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

String formatDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';

ImageProvider _avatarProvider(UserState u) => u.avatarPath != null
    ? FileImage(File(u.avatarPath!))
    : const NetworkImage(kDefaultAvatar) as ImageProvider;

/// Verify biometrics. Returns `true` if unavailable (fail-open for dev).
// BACKEND: Consider switching to fail-closed once production is ready.
Future<bool> _authenticateBiometrics() async {
  try {
    final withBio = await _localAuth.canCheckBiometrics;
    final supported = withBio || await _localAuth.isDeviceSupported();
    if (!supported) return true;
    return await _localAuth.authenticate(
      localizedReason: 'Authenticate to proceed',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  } catch (_) {
    return false;
  }
}

/// Fallback password prompt when biometrics are unavailable.
// BACKEND: Replace with server-side challenge endpoint.
Future<bool> _showPasswordDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final storedPassword = prefs.getString(_kUserPasswordKey) ?? 'password';
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (passCtrl.text == storedPassword) {
              Navigator.pop(ctx, true);
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Incorrect password')),
              );
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

// =============================================================================
// BACKEND-ADJACENT BUSINESS LOGIC
// =============================================================================

/// Append a transaction and reconcile balance.
// BACKEND: Mirror locally for optimistic UI, then POST to `/api/v1/transactions`.
void _addTransaction(Tx tx) {
  transactionsNotifier.value = [tx, ...transactionsNotifier.value];
  if (tx.isIncome) {
    balanceNotifier.value += tx.amount;
  } else {
    balanceNotifier.value -= tx.amount.abs();
  }
}

/// Auto-deduct overdue loans on app start.
// BACKEND: Prefer a scheduled job server-side; this is a client catch-up.
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

/// Apply monthly savings auto-cut on app start if due.
// BACKEND: Same – better handled by cron on the server.
void _checkSavingsAutoCut() {
  if (!savingsEnabledNotifier.value) return;
  final lastCut = lastSavingsCutNotifier.value;
  if (lastCut == null) return;

  final daysSince = DateTime.now().difference(lastCut).inDays;
  if (daysSince < 30) return;

  final amtToCut =
      missedSavingsNotifier.value ? _kMonthlySavingsMissed : _kMonthlySavings;

  if (balanceNotifier.value >= amtToCut) {
    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Savings Auto-Save',
      subtitle: 'Monthly Deposit',
      amount: -amtToCut,
      time: 'Just now',
      icon: Icons.savings_outlined,
      isIncome: false,
    ));
    savingsBalanceNotifier.value += amtToCut;
    missedSavingsNotifier.value = false;
  } else {
    missedSavingsNotifier.value = true;
  }
  lastSavingsCutNotifier.value = DateTime.now();
}

// =============================================================================
// ENTRY POINT
// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore theme preference.
  final prefs = await SharedPreferences.getInstance();
  darkModeNotifier.value = prefs.getBool('dark_mode') ?? false;

  // Persist theme changes.
  darkModeNotifier.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', darkModeNotifier.value);
  });

  // Persist user profile changes.
  // BACKEND: Replace with `PATCH /api/v1/me` call.
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

// =============================================================================
// ROOT APP + THEME
// =============================================================================

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Theme instances built once so no allocation per rebuild.
  static final ThemeData _lightTheme = _buildTheme(isDark: false);
  static final ThemeData _darkTheme = _buildTheme(isDark: true);
  static final ThemeData _baseTheme = ThemeData(useMaterial3: true);

  static const Color _lightOnSurface = Color(0xFF0A140D);
  static const Color _lightOnSurfaceVariant = Color(0xFF2B3A32);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);
  static const Color _darkOnSurfaceVariant = Color(0xFFD6E2DA);

  static ThemeData _buildTheme({required bool isDark}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kGreen,
      primary: isDark ? const Color(0xFF1B8462) : kGreen,
      secondary: isDark ? const Color(0xFFF85B6A) : kRed,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      surface: isDark ? const Color(0xFF0C1A13) : const Color(0xFFDDEEDD),
      onSurface: isDark ? _darkOnSurface : _lightOnSurface,
      onSurfaceVariant:
          isDark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? _darkOnSurface : _lightOnSurface,
        titleTextStyle: TextStyle(
          color: isDark ? _darkOnSurface : _lightOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? _darkOnSurface : _lightOnSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? const Color(0xFF14261C) : const Color(0xFFF2FAF3),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? _darkOnSurface : _lightOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color:
              isDark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant,
          fontSize: 15,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFFE8F0EA) : const Color(0xFF1A1A1A),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        textColor: isDark ? _darkOnSurface : _lightOnSurface,
        iconColor:
            isDark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant,
      ),
      dividerTheme:
          const DividerThemeData(color: Colors.transparent, thickness: 0),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
            color: isDark ? _darkOnSurface : _lightOnSurface),
        bodyMedium: TextStyle(
            color: isDark ? _darkOnSurface : _lightOnSurface),
        bodySmall: TextStyle(
            color:
                isDark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant),
        titleLarge: TextStyle(
          color: isDark ? _darkOnSurface : _lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: isDark ? _darkOnSurface : _lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          color: isDark ? _darkOnSurface : _lightOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Fixed base theme prevents MaterialApp's AnimatedTheme from
      // flickering when the real theme is swapped below.
      theme: _baseTheme,
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: darkModeNotifier,
          builder: (context, isDark, _) {
            final theme = isDark ? _darkTheme : _lightTheme;
            return Theme(
              data: theme,
              child: ScaffoldMessenger(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF050A07),
                                    const Color(0xFF010302),
                                  ]
                                : [
                                    const Color(0xFFF2F9F4),
                                    const Color(0xFFC9E5D1),
                                  ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      type: MaterialType.transparency,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      home: const AuthWrapper(),
    );
  }
}

// =============================================================================
// AUTH GATE
// =============================================================================

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

  /// Attempt silent login from cached session.
  // BACKEND: Exchange stored refresh token for a new access token here.
  Future<void> _checkQuickLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');
      final isBio = prefs.getBool('biometric_enabled') ?? false;
      final avatar = prefs.getString('user_avatar');

      if (name != null && email != null && name != 'User') {
        userNotifier.value = UserState(
          name: name,
          email: email,
          isBiometricEnabled: isBio,
          avatarPath: avatar,
        );
        if (isBio) {
          final success = await _localAuth.authenticate(
            localizedReason: 'Quick Login',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
          if (success) authNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Quick login failed: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoanAutoDeduction();
      _checkSavingsAutoCut();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ValueListenableBuilder<bool>(
      valueListenable: authNotifier,
      builder: (_, __, ___) =>
          authNotifier.value ? const HomeShell() : const LoginPage(),
    );
  }
}

// =============================================================================
// LOGIN
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

  /// Mock login. Stores password locally for later re-auth.
  // BACKEND: POST /api/v1/auth/login with { email, password }
  //   → { token, refresh_token, user }
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credentials')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserPasswordKey, password);

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                GlassContainer(
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(24),
                  blur: 20,
                  child: Icon(
                    Icons.account_balance,
                    color: Theme.of(context).colorScheme.primary,
                    size: 45,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                _LoginField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _LoginField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: kWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HOME SHELL (FLOATING GLASS NAVIGATION)
// =============================================================================

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ProfilePage(),
  ];

  Widget _navItem({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? colorOverride,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: colorOverride ??
                (active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: GlassContainer(
          height: 68,
          borderRadius: BorderRadius.circular(34),
          blur: 25,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                icon: _index == 0 ? Icons.home : Icons.home_outlined,
                active: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _navItem(
                icon: Icons.qr_code_scanner,
                active: false,
                colorOverride: kRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const QrScannerPage(returnToAmount: true),
                  ),
                ),
              ),
              _navItem(
                icon: _index == 1 ? Icons.person : Icons.person_outline,
                active: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HOME
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBalance(),
              const SizedBox(height: 24),
              _buildActions(),
              const SizedBox(height: 24),
              const AdCarousel(),
              const SizedBox(height: 24),
              _buildTransactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ValueListenableBuilder<UserState>(
      valueListenable: userNotifier,
      builder: (context, user, _) => Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: _avatarProvider(user),
          ),
          const SizedBox(width: 12),
          Text(
            'Hello, ${user.name.isEmpty ? "Bardia" : user.name}!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsPage(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance() {
    return Center(
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          // BACKEND: Subscribe to balance stream.
          ValueListenableBuilder<double>(
            valueListenable: balanceNotifier,
            builder: (context, balance, _) => Text(
              formatMoney(balance),
              style: TextStyle(
                color: balance < 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_outward,
            label: 'Send',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecipientSelectionPage(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.call_received,
            label: 'Receive',
            onTap: () => _showReceiveModal(context),
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
    );
  }

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // BACKEND: Subscribe to `GET /api/v1/transactions?limit=5`.
        ValueListenableBuilder<List<Tx>>(
          valueListenable: transactionsNotifier,
          builder: (context, txs, _) {
            if (txs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No recent transactions',
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final tx = txs[i];
                return GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  blur: 12,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx.icon,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.time,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.isIncome ? '+' : ''}${formatMoney(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: tx.isIncome
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showReceiveModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: GlassContainer(
          margin: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(30),
          blur: 30,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Receive Money',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: 'wallet://pay?code=$_kPaymentCode',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: kBlack,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: kBlack,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan to pay me',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  _kPaymentCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: _kPaymentCode),
                    );
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => GlassContainer(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        blur: 30,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'More Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Savings / Auto-Save'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Loan / Advance'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoanPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.subscriptions_outlined),
                title: const Text('Subscriptions'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Pay Bill'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBillMenu(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Education Payment'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEducationMenu(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => GlassContainer(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        blur: 30,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Select Biller',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('DPDC'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToBill(context, 'DPDC', 'Meter Number');
                },
              ),
              ListTile(
                title: const Text('DESCO'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToBill(context, 'DESCO', 'Meter Number');
                },
              ),
              ListTile(
                title: const Text('Dot Internet'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToBill(context, 'Dot Internet', 'Customer Number');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _goToBill(BuildContext context, String name, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillPaymentPage(billerName: name, idLabel: label),
      ),
    );
  }

  void _showEducationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => GlassContainer(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        blur: 30,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Select Institution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text(
                  'Shamsul Hoque Khan School and College',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToEducation(
                    context,
                    'Shamsul Hoque Khan School',
                    false,
                  );
                },
              ),
              ListTile(
                title: const Text('Dhaka City College'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToEducation(context, 'Dhaka City College', false);
                },
              ),
              ListTile(
                title: const Text('Dhaka College'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToEducation(context, 'Dhaka College', false);
                },
              ),
              ListTile(
                title: const Text('Daffodil International University'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToEducation(
                    context,
                    'Daffodil International University',
                    true,
                  );
                },
              ),
              ListTile(
                title: const Text('South-East University'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToEducation(
                    context,
                    'South-East University',
                    true,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _goToEducation(
    BuildContext context,
    String name,
    bool isUniversity,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EducationPaymentPage(
          institutionName: name,
          isUniversity: isUniversity,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NOTIFICATIONS
// =============================================================================

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 60,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No new notifications',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE
// =============================================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Pick an image from gallery and store path locally.
  // BACKEND: Upload to `/api/v1/me/avatar` (multipart) and store returned URL.
  Future<void> _pickAvatar() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      userNotifier.value =
          userNotifier.value.copyWith(avatarPath: picked.path);
    }
  }

  /// Edit display name.
  // BACKEND: PATCH /api/v1/me { name }
  Future<void> _editName() async {
    final ctrl =
        TextEditingController(text: userNotifier.value.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null &&
        result.isNotEmpty &&
        result != userNotifier.value.name) {
      userNotifier.value =
          userNotifier.value.copyWith(name: result);
    }
  }

  /// Trigger password reset email.
  // BACKEND: POST /api/v1/auth/reset { email }
  void _resetPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'A password reset link has been sent to your registered email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<UserState>(
        valueListenable: userNotifier,
        builder: (context, user, _) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarProvider(user),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                user.email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 40),
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              blur: 15,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Change Name'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editName,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Reset Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _resetPassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SETTINGS
// =============================================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Toggle biometric security (requires device auth).
  // BACKEND: PATCH /api/v1/me { biometric_enabled: bool }
  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final ok = await _authenticateBiometrics();
      if (ok) {
        userNotifier.value =
            userNotifier.value.copyWith(isBiometricEnabled: true);
      }
    } else {
      userNotifier.value =
          userNotifier.value.copyWith(isBiometricEnabled: false);
    }
  }

  /// Clear session and return to login.
  // BACKEND: POST /api/v1/auth/logout
  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authNotifier.value = false;
            },
            child: Text(
              'Log out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<UserState>(
        valueListenable: userNotifier,
        builder: (context, user, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              blur: 15,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: darkModeNotifier,
                    builder: (context, isDark, _) => SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                      ),
                      title: const Text('Dark Mode'),
                      value: isDark,
                      activeThumbColor:
                          Theme.of(context).colorScheme.primary,
                      onChanged: (v) => darkModeNotifier.value = v,
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Security'),
                    subtitle: const Text(
                      'Required for sending & quick login',
                    ),
                    value: user.isBiometricEnabled,
                    activeThumbColor:
                        Theme.of(context).colorScheme.primary,
                    onChanged: _toggleBiometrics,
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Log out',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HELP
// =============================================================================

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static final List<_HelpTopic> _topics = [
    const _HelpTopic(
      title: 'Home & Balance',
      icon: Icons.home_outlined,
      content:
          'The home screen displays your total wallet balance. You can see your most recent transactions at the bottom.',
    ),
    const _HelpTopic(
      title: 'Send Money',
      icon: Icons.arrow_outward,
      content:
          'To send money, tap "Send". Select a recent recipient or enter their code and confirm.',
    ),
    const _HelpTopic(
      title: 'Receive Money',
      icon: Icons.call_received,
      content:
          'Tap "Receive" to open your personal QR code. Anyone can scan to send you money.',
    ),
    const _HelpTopic(
      title: 'Fast Scan',
      icon: Icons.qr_code_scanner,
      content:
          'Tap the Scan icon in the bottom navigation bar to open the camera immediately.',
    ),
    const _HelpTopic(
      title: 'Savings & Auto-Save',
      icon: Icons.savings_outlined,
      content:
          'Under "More", enable Auto-Save to deduct 100 TK every 30 days. Locked for 1 year.',
    ),
    const _HelpTopic(
      title: 'Loan / Advance',
      icon: Icons.payments_outlined,
      content:
          'Take instant cash advance. Basic limit 1,000 TK, Pro 5,000 TK. Due in 30 days.',
    ),
    const _HelpTopic(
      title: 'Subscriptions',
      icon: Icons.subscriptions_outlined,
      content:
          'Buy Netflix, Spotify, Claude Pro, etc. directly from the app.',
    ),
    const _HelpTopic(
      title: 'Bills & Education',
      icon: Icons.receipt_long_outlined,
      content:
          'Pay electricity (DPDC/DESCO), internet, and education fees by entering your ID.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: _topics
            .map((t) => _HelpSection(topic: t))
            .toList(),
      ),
    );
  }
}

class _HelpTopic {
  final String title;
  final IconData icon;
  final String content;
  const _HelpTopic({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class _HelpSection extends StatelessWidget {
  final _HelpTopic topic;
  const _HelpSection({required this.topic});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: BorderRadius.circular(16),
      blur: 12,
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: Theme.of(context).colorScheme.onSurface,
          collapsedIconColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          textColor: Theme.of(context).colorScheme.onSurface,
          collapsedTextColor: Theme.of(context).colorScheme.onSurface,
          leading: Icon(
            topic.icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            topic.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                topic.content,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
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
// RECIPIENT SELECTION (SEND)
// =============================================================================

class RecipientSelectionPage extends StatefulWidget {
  const RecipientSelectionPage({super.key});
  @override
  State<RecipientSelectionPage> createState() =>
      _RecipientSelectionPageState();
}

class _RecipientSelectionPageState
    extends State<RecipientSelectionPage> {
  final _codeController = TextEditingController();

  // BACKEND: GET /api/v1/recipients/recent
  static const List<Map<String, dynamic>> _recentRecipients = [
    {'name': 'Arnold Smith', 'code': 'ARN-552-OLI'},
    {'name': 'Raiyan Sarker', 'code': 'RAI-991-XYZ'},
    {'name': 'Tanvir Hossain', 'code': 'TAN-331-ABC'},
  ];

  void _proceedToAmount(String code, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AmountPage(recipientCode: code, recipientName: name),
      ),
    );
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(returnToAmount: true),
      ),
    );
    if (result != null) _proceedToAmount(result, 'Scanned Recipient');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Send Money',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQR,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send to',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a recipient code or choose from recent.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                blur: 15,
                child: TextField(
                  controller: _codeController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter code (e.g. ARN-552-OLI)',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onSubmitted: (v) {
                    if (v.isNotEmpty) {
                      _proceedToAmount(v, 'Custom Recipient');
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentRecipients.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = _recentRecipients[i];
                  return GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    blur: 12,
                    padding: const EdgeInsets.all(16),
                    onTap: () => _proceedToAmount(
                      r['code'] as String,
                      r['name'] as String,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              NetworkImage(kDefaultAvatar),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r['code'] as String,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AMOUNT ENTRY & TRANSFER
// =============================================================================

class AmountPage extends StatefulWidget {
  final String recipientCode;
  final String recipientName;
  const AmountPage({
    super.key,
    required this.recipientCode,
    required this.recipientName,
  });

  @override
  State<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends State<AmountPage> {
  String _amount = '0';

  void _onKeyPress(String key) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (key == 'back') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else if (_amount == '0') {
        _amount = key;
      } else {
        if (_amount.contains('.') &&
            _amount.split('.')[1].length >= 2) {
          return;
        }
        _amount += key;
      }
    });
  }

  /// Confirm transfer: authorize → debit → navigate.
  // BACKEND: POST /api/v1/transfers
  //   { recipient: recipientCode, amount }
  //   → { transaction_id, new_balance }
  Future<void> _processTransfer() async {
    final amt = double.tryParse(_amount) ?? 0;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amt > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Insufficient balance. Please receive money first.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
    } else {
      authorized = await _showPasswordDialog(context);
    }

    if (!authorized) return;
    if (!mounted) return;

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Sent to ${widget.recipientName}',
      subtitle: 'Transfer',
      amount: -amt,
      time: 'Just now',
      icon: Icons.arrow_outward,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send Amount',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(16),
              blur: 15,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(kDefaultAvatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sending to',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.recipientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.recipientCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '৳$_amount',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: balanceNotifier,
            builder: (context, balance, _) => Text(
              'Available: ${formatMoney(balance)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _keyRow(['1', '2', '3']),
                _keyRow(['4', '5', '6']),
                _keyRow(['7', '8', '9']),
                _keyRow(['.', '0', 'back']),
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
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Transfer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        return InkWell(
          onTap: () => _onKeyPress(k),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            child: k == 'back'
                ? Icon(
                    Icons.backspace_outlined,
                    color:
                        Theme.of(context).colorScheme.onSurface,
                  )
                : Text(
                    k,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color:
                          Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SAVINGS
// =============================================================================

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});
  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _isLoading = false;

  /// Withdraw all savings (only allowed after 1-year lock-in).
  // BACKEND: POST /api/v1/savings/withdraw → { amount, new_balance }
  Future<void> _withdraw() async {
    final startDate = savingsStartDateNotifier.value;
    if (startDate == null) return;

    if (DateTime.now().difference(startDate).inDays < 365) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'You can only withdraw after 1 year.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    if (savingsBalanceNotifier.value <= 0) return;

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
      icon: Icons.savings_outlined,
      isIncome: true,
    ));

    savingsBalanceNotifier.value = 0;
    savingsEnabledNotifier.value = false;
    savingsStartDateNotifier.value = null;
    lastSavingsCutNotifier.value = null;
    missedSavingsNotifier.value = false;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      content: Text(
        'Successfully withdrawn ${formatMoney(amt)}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    ));
  }

  /// Enable/disable auto-save. Once enabled, locked for 1 year.
  // BACKEND: POST /api/v1/savings/auto-save { enabled }
  void _toggleAutoSave(bool val) {
    if (!val) {
      final startDate = savingsStartDateNotifier.value;
      if (startDate != null &&
          DateTime.now().difference(startDate).inDays < 365) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'Auto-save is locked for 1 year. You cannot turn it off.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Savings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Total Savings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: savingsBalanceNotifier,
                  builder: (context, balance, _) => Text(
                    formatMoney(balance),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                blur: 15,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: savingsEnabledNotifier,
                      builder: (context, enabled, _) =>
                          SwitchListTile(
                        secondary: Icon(
                          Icons.autorenew,
                          color:
                              Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text(
                          'Auto-Save 100 TK/month',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically cuts 100 TK every 30 days.',
                        ),
                        value: enabled,
                        activeThumbColor:
                            Theme.of(context).colorScheme.primary,
                        onChanged: _toggleAutoSave,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: missedSavingsNotifier,
                      builder: (context, missed, _) {
                        if (!missed) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          child: Text(
                            'Warning: You missed a payment! Next cut will be 210 TK (100 double + 10 penalty).',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildWarningBanner(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _withdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: kWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Withdraw Savings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Warning: Turning on Auto-Save locks your deposited savings for 1 year. You cannot turn it off or withdraw until then.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AD CAROUSEL
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _startAutoScroll());
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
    setState(() => _generateAds());
    _startAutoScroll();
  }

  /// Build the rotation list from current user state.
  // BACKEND: Optionally override with server-driven ad list.
  void _generateAds() {
    final ads = <AdItem>[];

    if (!isProNotifier.value) {
      ads.add(AdItem(
        title: 'Upgrade to Synapse Pro',
        subtitle: 'Get 5% cashback and higher loan limits.',
        icon: Icons.stars_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradePage()),
        ),
      ));
    }

    for (final sub in availableSubs) {
      if (sub.name != 'Synapse Pro' &&
          !purchasedSubsNotifier.value.contains(sub.name)) {
        ads.add(AdItem(
          title: 'Get ${sub.name}',
          subtitle:
              'Subscribe for only ${formatMoney(sub.price)}/month.',
          icon: sub.icon,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SubscriptionBenefitsPage(sub: sub),
            ),
          ),
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
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_ads.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage =
          (_currentPage + 1) % _ads.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _openUrl(String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (e) {
      debugPrint('URL launch failed: $e');
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
        onPageChanged: (i) => _currentPage = i,
        itemBuilder: (context, i) => _AdCard(ad: _ads[i]),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdItem ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ad.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              kBlack,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(ad.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LOAN / ADVANCE
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

  /// Disburse a new loan.
  // BACKEND: POST /api/v1/loans { amount }
  //   → { loan_id, due_date, amount }
  Future<void> _takeLoan() async {
    final amt = double.tryParse(_amountController.text) ?? 0;
    final maxLimit =
        isProNotifier.value ? _kLoanLimitPro : _kLoanLimitBasic;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (amt > maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Amount exceeds your limit of ${formatMoney(maxLimit)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }
    if (loanNotifier.value > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'You must clear your previous loan first.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
    loanDueDateNotifier.value =
        DateTime.now().add(const Duration(days: 30));

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Loan Disbursed',
      subtitle: 'Advance',
      amount: amt,
      time: 'Just now',
      icon: Icons.payments_outlined,
      isIncome: true,
    ));

    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      content: Text(
        'Loan of ${formatMoney(amt)} disbursed successfully!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    ));
  }

  /// Repay the outstanding loan in full.
  // BACKEND: POST /api/v1/loans/repay
  Future<void> _repayLoan() async {
    final amt = loanNotifier.value;
    if (amt <= 0) return;

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
      icon: Icons.check_circle_outline,
      isIncome: false,
    ));

    loanNotifier.value = 0;
    loanDueDateNotifier.value = null;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      content: Text(
        'Loan fully repaid!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Loan / Advance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.payments_outlined, size: 60),
              const SizedBox(height: 24),
              const Text(
                'Take a Loan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get instant funds. Repay within 30 days.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              _buildLimitCard(),
              const SizedBox(height: 20),
              ValueListenableBuilder<double>(
                valueListenable: loanNotifier,
                builder: (context, activeLoan, _) =>
                    activeLoan > 0
                        ? _buildActiveLoan(activeLoan)
                        : _buildLoanForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitCard() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Limit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isProNotifier,
            builder: (context, isPro, _) => Text(
              isPro ? _kLoanLimitProText : _kLoanLimitBasicText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoan(double activeLoan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Outstanding Loan',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(activeLoan),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<DateTime?>(
                valueListenable: loanDueDateNotifier,
                builder: (context, dueDate, _) => Text(
                  'Due Date: ${dueDate != null ? formatDate(dueDate) : "N/A"}',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'You must repay your current loan before taking a new one.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _repayLoan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: kWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Repay Loan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Amount (৳)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          child: Row(
            children: [
              const Padding(
                padding:
                    EdgeInsets.only(left: 20, right: 12),
                child: Text(
                  '৳',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoBanner(),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _takeLoan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: kWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Take Loan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your loan will be due in 30 days. If unpaid, the amount will be automatically deducted, potentially resulting in a negative balance.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SYNAPSE PRO UPGRADE
// =============================================================================

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});
  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  bool _isLoading = false;

  /// Purchase Synapse Pro.
  // BACKEND: POST /api/v1/subscriptions { product: "synapse_pro" }
  Future<void> _processUpgrade() async {
    if (_kProPrice > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Insufficient balance. Please take a loan or receive money first.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
    purchasedSubsNotifier.value = [
      ...purchasedSubsNotifier.value,
      'Synapse Pro',
    ];

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Synapse Pro Upgrade',
      subtitle: 'Subscription',
      amount: -_kProPrice,
      time: 'Just now',
      icon: Icons.stars_outlined,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Synapse Pro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Upgrade to Synapse Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock premium features and get more out of your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              _buildFeatures(),
              const SizedBox(height: 40),
              const Text(
                'Monthly Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '৳500.00 / month',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: kWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Subscribe for ৳500',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          _FeatureRow(
            icon: Icons.check_circle_outline,
            text: '5% Cashback on all bills',
          ),
          SizedBox(height: 16),
          _FeatureRow(
            icon: Icons.check_circle_outline,
            text: 'Higher loan limit (up to ৳5,000)',
          ),
          SizedBox(height: 16),
          _FeatureRow(
            icon: Icons.check_circle_outline,
            text: 'Priority customer support',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SUBSCRIPTIONS (catalog + benefits + checkout)
// =============================================================================

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: availableSubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) =>
            _buildSubCard(context, availableSubs[i]),
      ),
    );
  }

  Widget _buildSubCard(BuildContext context, SubModel sub) {
    if (sub.name == 'Synapse Pro') {
      return ValueListenableBuilder<bool>(
        valueListenable: isProNotifier,
        builder: (context, isPro, _) =>
            isPro ? _buildProActive(context) : _buildSubItem(context, sub),
      );
    }
    return _buildSubItem(context, sub);
  }

  Widget _buildProActive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars_outlined,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Synapse Pro Active',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            color: kWhite,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(BuildContext context, SubModel sub) {
    final isPro = sub.name == 'Synapse Pro';
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 12,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isPro
              ? const UpgradePage()
              : SubscriptionBenefitsPage(sub: sub),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sub.icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro
                      ? 'Get 5% cashback and higher limits'
                      : 'Monthly subscription',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(sub.price),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionBenefitsPage extends StatelessWidget {
  final SubModel sub;
  const SubscriptionBenefitsPage({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sub.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sub.icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Get ${sub.name}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See what is included in your subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              _buildBenefits(context),
              const SizedBox(height: 40),
              const Text(
                'Monthly Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatMoney(sub.price)} / month',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionCheckoutPage(sub: sub),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Proceed to Pay ${formatMoney(sub.price)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sub.benefits
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class SubscriptionCheckoutPage extends StatefulWidget {
  final SubModel sub;
  const SubscriptionCheckoutPage({super.key, required this.sub});
  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState
    extends State<SubscriptionCheckoutPage> {
  final _accountIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountIdController.dispose();
    super.dispose();
  }

  /// Complete subscription purchase.
  // BACKEND: POST /api/v1/subscriptions { product, account_id }
  Future<void> _processPurchase() async {
    final accountId = _accountIdController.text.trim();
    if (accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Please enter your ${widget.sub.emailLabel}',
        ),
      ));
      return;
    }

    if (widget.sub.price > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Insufficient balance. Please take a loan or receive money.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
    } else {
      authorized = await _showPasswordDialog(context);
    }
    if (!authorized) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    purchasedSubsNotifier.value = [
      ...purchasedSubsNotifier.value,
      widget.sub.name,
    ];

    _addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${widget.sub.name} Subscription',
      subtitle: 'For $accountId',
      amount: -widget.sub.price,
      time: 'Just now',
      icon: widget.sub.icon,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buy ${widget.sub.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.sub.icon,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the account information needed to activate your ${widget.sub.name} subscription.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildAccountField(context),
              const SizedBox(height: 32),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummary(context),
              const SizedBox(height: 40),
              _buildPayButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountField(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              Icons.person_outline,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _accountIdController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.sub.emailLabel,
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription Fee',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatMoney(widget.sub.price),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formatMoney(widget.sub.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: kWhite,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ${formatMoney(widget.sub.price)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// =============================================================================
// QR SCANNER
// =============================================================================

class QrScannerPage extends StatefulWidget {
  final bool returnToAmount;
  const QrScannerPage({super.key, this.returnToAmount = false});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Decode a scanned QR string into a recipient code.
  // BACKEND: Validate code with `GET /api/v1/recipients/{code}` before
  // navigating to AmountPage.
  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      var code = raw;
      if (raw.startsWith('wallet://pay') || raw.contains('code=')) {
        try {
          code = Uri.parse(raw).queryParameters['code'] ?? raw;
        } catch (_) {}
      }

      if (widget.returnToAmount) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AmountPage(
              recipientCode: code,
              recipientName: 'Scanned Recipient',
            ),
          ),
        );
      } else {
        Navigator.pop(context, code);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhite),
        title: const Text(
          'Scan QR',
          style: TextStyle(
            color: kWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: kWhite, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align QR within the frame',
                style: TextStyle(color: kWhite, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUCCESS
// =============================================================================

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 50,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaction Successful',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildDetails(context, now),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, DateTime now) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _DetailRow(
            label: 'Status',
            value: 'Completed',
            valueColor: kGreen,
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Reference',
            value:
                'REF${now.millisecondsSinceEpoch.toString().substring(7)}',
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Date',
            value: '${now.day}/${now.month}/${now.year}',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color:
                valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BILL PAYMENT
// =============================================================================

class BillPaymentPage extends StatefulWidget {
  final String billerName;
  final String idLabel;
  const BillPaymentPage({
    super.key,
    required this.billerName,
    required this.idLabel,
  });

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

  /// Fetch current due amount from biller.
  // BACKEND: GET /api/v1/bills/{biller}?id={meter/customer}
  //   → { due_amount }
  Future<void> _checkBill() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.idLabel}')),
      );
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

  /// Pay the bill.
  // BACKEND: POST /api/v1/bills/pay { biller, id, amount }
  Future<void> _processPayment() async {
    if (_dueAmount! > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Insufficient balance. Please take a loan or receive money.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
      icon: Icons.receipt_long_outlined,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_dueAmount != null) {
              setState(() => _dueAmount = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.billerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _dueAmount == null
              ? _buildInputScreen(context)
              : _buildBillScreen(context),
        ),
      ),
    );
  }

  Widget _buildInputScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.receipt_long_outlined, size: 60),
        const SizedBox(height: 24),
        Text(
          'Pay ${widget.billerName} Bill',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your ${widget.idLabel} to fetch the current due amount.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 12),
                child: Icon(
                  Icons.numbers,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.idLabel,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
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
            onPressed: _isLoading ? null : _checkBill,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: kWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Check Bill',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Total Due',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.85),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '৳${_dueAmount!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _detail('Biller', widget.billerName),
              const SizedBox(height: 16),
              _detail(widget.idLabel, _idController.text),
              const SizedBox(height: 16),
              _detail('Status', 'Unpaid',
                  valueColor: Colors.orange),
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
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pay ৳${_dueAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color:
                valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// EDUCATION PAYMENT
// =============================================================================

class EducationPaymentPage extends StatefulWidget {
  final String institutionName;
  final bool isUniversity;
  const EducationPaymentPage({
    super.key,
    required this.institutionName,
    required this.isUniversity,
  });

  @override
  State<EducationPaymentPage> createState() =>
      _EducationPaymentPageState();
}

class _EducationPaymentPageState extends State<EducationPaymentPage> {
  final _idController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _studentName;
  String? _studentDepartment;

  static const List<String> _bdNames = [
    'Tanvir Hossain', 'Sajid Hasan', 'Raiyan Sarker',
    'Mehedi Hasan', 'Rafiul Islam', 'Fahim Shahriar',
    'Nusrat Jahan', 'Tasnim Rahman', 'Arif Chowdhury',
    'Sumaiya Akter', 'Mahmudul Hasan', 'Sadia Islam',
  ];

  static const List<String> _departments = [
    'Computer Science & Engineering (CSE)',
    'Bachelor of Business Administration (BBA)',
    'Electrical & Electronic Engineering (EEE)',
    'English Literature',
    'Pharmacy',
    'Architecture',
  ];

  @override
  void dispose() {
    _idController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Look up student details by ID.
  // BACKEND: GET /api/v1/education/{institution}/students/{id}
  //   → { name, department }
  Future<void> _findStudent() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Student ID')),
      );
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
        final deptIndex =
            (id.hashCode % _departments.length).abs();
        _studentDepartment = _departments[deptIndex];
      }
    });
  }

  /// Process education fee payment.
  // BACKEND: POST /api/v1/education/pay
  //   { institution, student_id, amount }
  Future<void> _processPayment() async {
    final amount =
        double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
        ),
      );
      return;
    }

    if (amount > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          'Insufficient balance. Please take a loan or receive money.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ));
      return;
    }

    bool authorized = false;
    if (userNotifier.value.isBiometricEnabled) {
      authorized = await _authenticateBiometrics();
      if (!authorized) {
        authorized = await _showPasswordDialog(context);
      }
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
      icon: Icons.school_outlined,
      isIncome: false,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_studentName != null) {
              setState(() {
                _studentName = null;
                _studentDepartment = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Education Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _studentName == null
              ? _buildInputScreen(context)
              : _buildStudentScreen(context),
        ),
      ),
    );
  }

  Widget _buildInputScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.school_outlined, size: 60),
        const SizedBox(height: 24),
        Text(
          widget.institutionName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the Student ID to fetch details.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 12),
                child: Icon(
                  Icons.badge_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _idController,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Student ID',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
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
            onPressed: _isLoading ? null : _findStudent,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: kWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Find Student',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentScreen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.person_outline, size: 60),
        const SizedBox(height: 24),
        const Text(
          'Student Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the amount you want to pay for this student.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 30),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _detail('Institution', widget.institutionName),
              const SizedBox(height: 16),
              _detail('Student Name', _studentName!),
              if (widget.isUniversity) ...[
                const SizedBox(height: 16),
                _detail('Department', _studentDepartment!),
              ],
              const SizedBox(height: 16),
              _detail('Student ID', _idController.text),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Amount to Pay (৳)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blur: 15,
          child: Row(
            children: [
              const Padding(
                padding:
                    EdgeInsets.only(left: 20, right: 12),
                child: Text(
                  '৳',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                  ),
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
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 18),
                SizedBox(width: 8),
                Text(
                  'Proceed to Pay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ??
                  Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

/// Frosted glass container with `BackdropFilter` blur.
///
/// Respects the active theme: light mode uses a lighter tint, dark mode
/// a darker one. Tap handling wraps child in an `InkWell` with matching
/// clip radius.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blur = 15.0,
    this.color,
    this.borderColor,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = color ??
        Colors.white.withValues(alpha: isDark ? 0.18 : 0.55);
    final end =
        color ?? Colors.white.withValues(alpha: isDark ? 0.08 : 0.28);
    final border = borderColor ??
        Colors.white.withValues(alpha: isDark ? 0.22 : 0.70);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: border, width: 0.5),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}