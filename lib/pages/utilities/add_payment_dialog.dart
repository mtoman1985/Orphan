import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orphan/models/payment.dart';
import 'package:orphan/models/sponsor.dart';
import 'package:intl/intl.dart';

class AddPaymentDialog extends StatefulWidget {
  final List<String> currencies;
  final String? selectedCurrency;
  final String? selectedSponsorId;
  final List<Sponsor> ongoingSponsors; // List of ongoing sponsors
  final Payment? payment; // Optional payment for editing
  final Function(Payment payment) onSave;

  const AddPaymentDialog({
    Key? key,
    required this.currencies,
    this.selectedCurrency,
    this.selectedSponsorId,
    this.ongoingSponsors = const [],
    this.payment,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  late TextEditingController amountCtl;
  late TextEditingController dateCtl;
  late TextEditingController noteCtl;
  DateTime? selectedDate;
  String? selectedCurrency;
  Sponsor? selectedSponsor;

  @override
  void initState() {
    super.initState();
    amountCtl = TextEditingController();
    dateCtl = TextEditingController();
    noteCtl = TextEditingController();

    if (widget.payment != null) {
      // Editing mode
      amountCtl.text = widget.payment!.amount.toString();
      selectedDate = widget.payment!.paidAt;
      selectedCurrency = widget.payment!.currency;
      noteCtl.text = widget.payment!.note ?? '';

      // Find the sponsor from the payment
      if (widget.ongoingSponsors.isNotEmpty &&
          widget.payment!.sponsorId != null) {
        try {
          selectedSponsor = widget.ongoingSponsors.firstWhere(
            (s) => s.id == widget.payment!.sponsorId,
          );
        } catch (_) {
          // If not in ongoing, maybe it was an old sponsor?
          // For now, we only show ongoing sponsors in the dropdown if adding,
          // but if editing, we might need more.
        }
      }
    } else {
      // Adding mode
      selectedDate = DateTime.now();
      selectedCurrency =
          widget.selectedCurrency ??
          (widget.currencies.isNotEmpty ? widget.currencies.first : 'شيكل');

      // Set initial sponsor if available
      if (widget.ongoingSponsors.isNotEmpty) {
        selectedSponsor = widget.ongoingSponsors.first;
        _updateAmountAndCurrencyFromSponsor(selectedSponsor!);
      }
    }

    if (selectedDate != null) {
      dateCtl.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
    }
  }

  /// Update amount and currency based on selected sponsor
  void _updateAmountAndCurrencyFromSponsor(Sponsor sponsor) {
    amountCtl.text = sponsor.amount.toString();
    selectedCurrency = sponsor.currency;
    selectedSponsor = sponsor;
  }

  @override
  void dispose() {
    amountCtl.dispose();
    dateCtl.dispose();
    noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.payment != null;

    return AlertDialog(
      title: Text(isEditing ? 'تعديل دفعة' : 'إضافة دفعة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sponsor Selection Dropdown
            if (widget.ongoingSponsors.isNotEmpty) ...[
              DropdownButtonFormField<Sponsor>(
                value: selectedSponsor,
                decoration: const InputDecoration(
                  labelText: 'اختر الكفيل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                isExpanded: true,
                items:
                    widget.ongoingSponsors
                        .map(
                          (sponsor) => DropdownMenuItem(
                            value: sponsor,
                            child: Text(sponsor.name),
                          ),
                        )
                        .toList(),
                onChanged: (sponsor) {
                  if (sponsor != null) {
                    setState(() {
                      _updateAmountAndCurrencyFromSponsor(sponsor);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Info: Amount and currency are auto-populated from sponsor
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ⓘ المبلغ والعملة يتم ملؤهم تلقائياً من بيانات الكفيل ويمكن تغييرهم',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              if (!isEditing) const SizedBox(height: 16),
            ],
            // Amount Field
            TextFormField(
              controller: amountCtl,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'أدخل المبلغ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 16),

            // Currency Dropdown
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'العملة',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items:
                  widget.currencies
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => selectedCurrency = value);
              },
            ),
            const SizedBox(height: 16),

            // Date Field
            TextFormField(
              controller: dateCtl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'تاريخ الدفع',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        dateCtl.text = DateFormat('yyyy-MM-dd').format(picked);
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note Field
            TextFormField(
              controller: noteCtl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'أضف ملاحظات عن الدفعة',
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (amountCtl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال المبلغ')),
              );
              return;
            }

            final amount = double.tryParse(amountCtl.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
              );
              return;
            }

            final payment = Payment(
              id:
                  isEditing
                      ? widget.payment!.id
                      : DateTime.now().millisecondsSinceEpoch.toString(),
              childId: widget.payment?.childId ?? '',
              sponsorId: selectedSponsor?.id,
              amount: amount,
              currency: selectedCurrency,
              paidAt: selectedDate ?? DateTime.now(),
              note: noteCtl.text.isNotEmpty ? noteCtl.text : null,
            );

            widget.onSave(payment);
            Navigator.pop(context);
          },
          child: Text(isEditing ? 'تحديث الدفعة' : 'حفظ الدفعة'),
        ),
      ],
    );
  }
}
