import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/auth_helpers.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../success/success_page.dart';

// =============================================================================
// EDUCATION PAYMENT PAGE
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
  State<EducationPaymentPage> createState() => _EducationPaymentPageState();
}

class _EducationPaymentPageState extends State<EducationPaymentPage> {
  final _idController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _studentName;
  String? _studentDepartment;

  final List<String> _bdNames = [
    "Tanvir Hossain",
    "Sajid Hasan",
    "Raiyan Sarker",
    "Mehedi Hasan",
    "Rafiul Islam",
    "Fahim Shahriar",
    "Nusrat Jahan",
    "Tasnim Rahman",
    "Arif Chowdhury",
    "Sumaiya Akter",
    "Mahmudul Hasan",
    "Sadia Islam",
  ];

  final List<String> _departments = [
    "Computer Science & Engineering (CSE)",
    "Bachelor of Business Administration (BBA)",
    "Electrical & Electronic Engineering (EEE)",
    "English Literature",
    "Pharmacy",
    "Architecture",
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
        final deptIndex = (id.hashCode % _departments.length).abs();
        _studentDepartment = _departments[deptIndex];
      }
    });
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > balanceNotifier.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kRed,
          content: Text(
            'Insufficient balance. Please take a loan or receive money.',
          ),
        ),
      );
      return;
    }

    final authorized = await showPasswordDialog(context);

    if (!authorized) return;
    if (!mounted) return;

    addTransaction(
      Tx(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.institutionName,
        subtitle: 'Education Payment',
        amount: -amount,
        time: 'Just now',
        icon: Icons.school,
        isIncome: false,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
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
          },
        ),
        title: const Text(
          'Education Payment',
          style: TextStyle(color: kBlack, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              _studentName == null
                  ? _buildInputScreen()
                  : _buildStudentInfoScreen(),
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
        Text(
          widget.institutionName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the Student ID to fetch details.',
          style: TextStyle(color: kTextGrey),
        ),
        const SizedBox(height: 40),
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
            ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
        const Text(
          'Student Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the amount you want to pay for this student.',
          style: TextStyle(color: kTextGrey),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
          ),
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
        const Text(
          'Amount to Pay (৳)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 10),
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Text(
                    '৳',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kBlack,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kBlack,
                    ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 18),
                SizedBox(width: 8),
                Text(
                  'Proceed to Pay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? kBlack,
            ),
          ),
        ),
      ],
    );
  }
}
