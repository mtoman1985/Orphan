import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/finance/finance_payment.dart';
import '../../models/finance/customer.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';

class PaymentFormPage extends StatefulWidget {
  final FinancePayment? payment;
  const PaymentFormPage({super.key, this.payment});

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _paymentType = 'قبض'; // 'قبض' or 'صرف'
  DateTime _paymentDate = DateTime.now();
  Customer? _selectedCustomer;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'نقد';

  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customers = await SqliteService().listCustomers();

    if (widget.payment != null) {
      _paymentType = widget.payment!.paymentType;
      _paymentDate = widget.payment!.paymentDate;
      _paymentMethod = widget.payment!.paymentMethod;
      _amountController.text = widget.payment!.paymentAmount.toString();
      _notesController.text = widget.payment!.notes ?? '';

      if (customers.isNotEmpty) {
        try {
          _selectedCustomer = customers.firstWhere(
            (c) => c.customerId == widget.payment!.customerId,
          );
        } catch (_) {}
      }
    }

    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.get('select_customer_msg'),
            ),
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.get('valid_amount_msg'),
            ),
          ),
        );
        return;
      }

      final payment = FinancePayment(
        paymentId: widget.payment?.paymentId,
        customerId: _selectedCustomer!.customerId!,
        currency: 'USD', // Default
        currencyTransfer: 1.0,
        paymentAmount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _paymentDate,
        paymentType: _paymentType,
        notes: _notesController.text,
        createdAt: widget.payment?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.payment == null) {
        await SqliteService().insertFinancePayment(payment);
      } else {
        await SqliteService().updateFinancePayment(payment);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReceipt = _paymentType == 'قبض';
    final primaryColor = isReceipt ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isReceipt
              ? l10n.get('new_receipt_voucher')
              : l10n.get('new_payment_voucher'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Type Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap:
                                    () => setState(() => _paymentType = 'قبض'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isReceipt
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(12),
                                    ),
                                    border:
                                        isReceipt
                                            ? Border.all(color: Colors.green)
                                            : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.get('receipt_voucher'),
                                      style: GoogleFonts.cairo(
                                        color:
                                            isReceipt
                                                ? Colors.green[800]
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap:
                                    () => setState(() => _paymentType = 'صرف'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        !isReceipt
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(12),
                                    ),
                                    border:
                                        !isReceipt
                                            ? Border.all(color: Colors.orange)
                                            : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.get('payment_voucher'),
                                      style: GoogleFonts.cairo(
                                        color:
                                            !isReceipt
                                                ? Colors.orange[800]
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Customer>(
                              value: _selectedCustomer,
                              decoration: InputDecoration(
                                labelText: l10n.get('financial_party'),
                                prefixIcon: const Icon(Icons.person),
                                border: const OutlineInputBorder(),
                              ),
                              items:
                                  _customers
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c.customerName),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) =>
                                      setState(() => _selectedCustomer = val),
                              validator:
                                  (val) =>
                                      val == null
                                          ? l10n.get('required_field')
                                          : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n.get('amount_label'),
                                prefixIcon: const Icon(Icons.attach_money),
                                border: const OutlineInputBorder(),
                                suffixText: 'USD',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator:
                                  (val) =>
                                      (val == null || val.isEmpty)
                                          ? l10n.get('required_field')
                                          : null,
                            ),
                            const SizedBox(height: 20),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null)
                                  setState(() => _paymentDate = picked);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.get('date_label'),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: const OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormat('yyyy-MM-dd').format(_paymentDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: InputDecoration(
                                labelText: l10n.get('payment_method_label'),
                                prefixIcon: const Icon(Icons.credit_card),
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'نقد',
                                  child: Text(l10n.get('cash_label')),
                                ),
                                DropdownMenuItem(
                                  value: 'شيك',
                                  child: Text(l10n.get('check_label')),
                                ),
                                DropdownMenuItem(
                                  value: 'تحويل',
                                  child: Text(l10n.get('transfer_label')),
                                ),
                              ],
                              onChanged:
                                  (val) =>
                                      setState(() => _paymentMethod = val!),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: l10n.get('notes_statement'),
                                prefixIcon: const Icon(Icons.note),
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _savePayment,
                          child: Text(
                            l10n.get('save_voucher'),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}
