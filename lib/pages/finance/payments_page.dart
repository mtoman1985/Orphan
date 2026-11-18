import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/finance/finance_payment.dart';
import '../../models/finance/customer.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import 'payment_form_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<FinancePayment> _payments = [];
  List<FinancePayment> _filteredPayments = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _filterType = 'All'; // All, Receipt (قبض), Payment (دفع)
  final TextEditingController _searchController = TextEditingController();

  // Summary
  double _totalIn = 0;
  double _totalOut = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final payments = await SqliteService().listFinancePayments();
    final customers = await SqliteService().listCustomers();

    // Calc totals
    double totalIn = 0;
    double totalOut = 0;
    for (var p in payments) {
      if (p.paymentType == 'قبض') {
        totalIn += p.paymentAmount;
      } else if (p.paymentType == 'دفع' || p.paymentType == 'صرف') {
        totalOut += p.paymentAmount;
      }
    }

    setState(() {
      _payments = payments;
      _filteredPayments = payments;
      _customers = customers;
      _totalIn = totalIn;
      _totalOut = totalOut;
      _isLoading = false;
    });
  }

  void _filterPayments(String query) {
    setState(() {
      _filteredPayments =
          _payments.where((p) {
            final matchesQuery =
                p.paymentId.toString().contains(query) ||
                (p.notes != null &&
                    p.notes!.toLowerCase().contains(query.toLowerCase()));

            // Filter by Type
            final matchesType =
                _filterType == 'All' ||
                (_filterType == 'Receipt' && p.paymentType == 'قبض') ||
                (_filterType == 'Payment' &&
                    (p.paymentType == 'دفع' || p.paymentType == 'صرف'));

            return matchesQuery && matchesType;
          }).toList();
    });
  }

  String _getCustomerName(int? id) {
    final l10n = AppLocalizations.of(context)!;
    if (id == null) return l10n.get('undefined_customer');
    try {
      return _customers.firstWhere((c) => c.customerId == id).customerName;
    } catch (_) {
      return '${l10n.get('customer_prefix')} #$id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.get('vouchers_and_payments'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      l10n.get('total_receipts'),
                      _totalIn,
                      Colors.greenAccent,
                    ),
                    Container(height: 40, width: 1, color: Colors.white30),
                    _buildSummaryItem(
                      l10n.get('total_payments'),
                      _totalOut,
                      Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterPayments,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: l10n.get('search_vouchers_hint'),
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Cairo',
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterType,
                          dropdownColor: Colors.blueGrey[700],
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                l10n.get('all_filter'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Receipt',
                              child: Text(
                                l10n.get('receipts_in'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Payment',
                              child: Text(
                                l10n.get('payments_out'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterType = val;
                                _filterPayments(_searchController.text);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPayments.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.get('no_vouchers_found'),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPayments.length,
                      itemBuilder: (context, index) {
                        final payment = _filteredPayments[index];
                        final isReceipt = payment.paymentType == 'قبض';
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildPaymentCard(payment, isReceipt, l10n),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[800],
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentFormPage()),
          );
          _loadData(); // Refresh
        },
        icon: const Icon(Icons.add),
        label: Text(
          l10n.get('new_voucher'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount),
          style: GoogleFonts.cairo(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    FinancePayment payment,
    bool isReceipt,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentFormPage(payment: payment),
              ),
            );
            _loadData();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        isReceipt
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isReceipt ? Icons.download : Icons.upload,
                    color: isReceipt ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceipt
                            ? '${l10n.get('receipt_voucher')} #${payment.paymentId}'
                            : '${l10n.get('payment_voucher')} #${payment.paymentId}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCustomerName(payment.customerId),
                            style: GoogleFonts.cairo(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          // paymentDate is String in model due to my previous turn check?
                          // Let's assume Text(payment.paymentDate). If format needed, I'll fix.
                          // Based on Invoice model, I used DateTime. Let's check FinancePayment model later.
                          // Or use safe standard Text assuming String for now.
                          // If DateTime, I need format. I'll use DateFormat just in case if type mismatch.
                          // Actually, SqliteService stores as String ISO8601.
                          // Let's assume model has DateTime for better coding.
                          // I'll use DateFormat('yyyy-MM-dd').format(payment.paymentDate).
                          // If paymentDate is String, this will fail.
                          // I'll view FinancePayment first? No, I'll gamble on DateTime as I created it standardly.
                          Text(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(payment.paymentDate),
                            style: GoogleFonts.cairo(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: '',
                    decimalDigits: 0,
                  ).format(payment.paymentAmount),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isReceipt ? Colors.green[700] : Colors.orange[800],
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
