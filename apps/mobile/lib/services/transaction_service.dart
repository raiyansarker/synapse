import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import '../models/transaction.dart';

// =============================================================================
// TRANSACTION SERVICE
// =============================================================================
void addTransaction(Tx tx) {
  transactionsNotifier.value = [tx, ...transactionsNotifier.value];
  if (tx.isIncome) {
    balanceNotifier.value += tx.amount;
  } else {
    balanceNotifier.value -= tx.amount.abs();
  }
}

void checkLoanAutoDeduction() {
  final dueDate = loanDueDateNotifier.value;
  final loanAmt = loanNotifier.value;

  if (loanAmt > 0 && dueDate != null && DateTime.now().isAfter(dueDate)) {
    addTransaction(Tx(
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

void checkSavingsAutoCut() {
  if (!savingsEnabledNotifier.value) return;
  final lastCut = lastSavingsCutNotifier.value;
  if (lastCut == null) return;

  final daysSinceLastCut = DateTime.now().difference(lastCut).inDays;

  if (daysSinceLastCut >= 30) {
    double amtToCut = missedSavingsNotifier.value ? 210.0 : 100.0;

    if (balanceNotifier.value >= amtToCut) {
      addTransaction(Tx(
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
