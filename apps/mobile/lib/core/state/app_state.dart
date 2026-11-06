import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_colors.dart';
import '../../models/user_state.dart';
import '../../models/transaction.dart';

// =============================================================================
// GLOBAL STATE NOTIFIERS
// =============================================================================
// Auth state (defaulted to true for testing to bypass login)
final ValueNotifier<bool> authNotifier = ValueNotifier(true);
final ValueNotifier<int> shellTabIndex = ValueNotifier(0);
final ValueNotifier<UserState> userNotifier = ValueNotifier(
  const UserState(name: kHardcodedName, email: 'bardia@synapse.com'),
);
final LocalAuthentication localAuth = LocalAuthentication();
String mockUserPassword = 'password';

// --- DYNAMIC DATA NOTIFIERS ---
final ValueNotifier<List<Tx>> transactionsNotifier = ValueNotifier([
  const Tx(
    id: 'TX-10482',
    title: 'Salary Deposit',
    subtitle: 'Income',
    amount: 32000.0,
    time: 'Today, 10:30 AM',
    icon: Icons.work_outline,
    isIncome: true,
  ),
  const Tx(
    id: 'TX-10471',
    title: 'Tahmid Adim',
    subtitle: 'Transfer',
    amount: 420.0,
    time: 'Today, 01:05 PM',
    icon: Icons.file_download_outlined,
    isIncome: true,
  ),
  const Tx(
    id: 'TX-10466',
    title: 'Cafe Rio',
    subtitle: 'Food',
    amount: 220.0,
    time: 'Today, 08:40 AM',
    icon: Icons.local_cafe_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10458',
    title: 'Pathao',
    subtitle: 'Ride',
    amount: 185.0,
    time: 'Today, 07:55 AM',
    icon: Icons.directions_car_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10421',
    title: 'Grocery Store',
    subtitle: 'Payment',
    amount: 2450.0,
    time: 'Yesterday, 07:15 PM',
    icon: Icons.local_grocery_store_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10409',
    title: 'Nusrat Jahan',
    subtitle: 'Transfer',
    amount: 430.0,
    time: 'Yesterday, 11:20 AM',
    icon: Icons.file_upload_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10388',
    title: 'Netflix',
    subtitle: 'Subscription',
    amount: 450.0,
    time: 'Yesterday, 09:00 AM',
    icon: Icons.subscriptions_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10312',
    title: 'Electricity Bill',
    subtitle: 'Bills',
    amount: 1850.0,
    time: '2 Nov, 03:20 PM',
    icon: Icons.bolt_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10340',
    title: 'House Rent',
    subtitle: 'Rent',
    amount: 18000.0,
    time: '1 Nov, 09:00 AM',
    icon: Icons.home_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10277',
    title: 'Pharmacy',
    subtitle: 'Health',
    amount: 640.0,
    time: '30 Oct, 08:15 PM',
    icon: Icons.local_pharmacy_outlined,
    isIncome: false,
  ),
  const Tx(
    id: 'TX-10241',
    title: 'Freelance Design',
    subtitle: 'Income',
    amount: 8500.0,
    time: '28 Oct, 04:45 PM',
    icon: Icons.payments_outlined,
    isIncome: true,
  ),
  const Tx(
    id: 'TX-10202',
    title: 'DESCO Cashback',
    subtitle: 'Rewards',
    amount: 35.50,
    time: '25 Oct, 02:10 PM',
    icon: Icons.redeem_outlined,
    isIncome: true,
  ),
]);
final ValueNotifier<double> balanceNotifier = ValueNotifier(84250.80);

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
