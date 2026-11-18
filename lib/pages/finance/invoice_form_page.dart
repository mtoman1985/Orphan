import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/finance/invoice.dart';
import '../../models/finance/customer.dart';
import '../../models/finance/item.dart';
import '../../models/finance/purchase.dart';
import '../../models/finance/sale.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';

class InvoiceFormPage extends StatefulWidget {
  final Invoice? invoice;
  const InvoiceFormPage({super.key, this.invoice});

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _invoiceType = 'Sale'; // 'Sale' or 'Purchase'
  DateTime _invoiceDate = DateTime.now();
  Customer? _selectedCustomer;
  String? _paymentMethod = 'cash';
  String? _notes;

  // Data Lists
  List<Customer> _customers = [];
  List<Item> _allItems = [];

  // Line Items (Wrapper to handle both Sale/Purchase logic in UI)
  List<Map<String, dynamic>> _lineItems = [];
  // Map structure: { 'item': Item object, 'quantity': double, 'price': double, 'total': double }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customers = await SqliteService().listCustomers();
    final items = await SqliteService().listItems();

    // If editing, load existing invoice details
    if (widget.invoice != null) {
      _invoiceType = widget.invoice!.invoiceType;
      _invoiceDate = widget.invoice!.invoiceDate;
      _paymentMethod = widget.invoice!.paymentMethod;
      _notes = widget.invoice!.notes;

      // Find selected customer
      if (customers.isNotEmpty) {
        try {
          _selectedCustomer = customers.firstWhere(
            (c) => c.customerId == widget.invoice!.customerId,
          );
        } catch (_) {
          // Customer might be deleted? Handle gracefully
          if (customers.isNotEmpty) _selectedCustomer = customers.first;
        }
      }

      // Load line items (Purchases or Sales)
      // Note: Assuming Sales/Purchases tables are populated
      // Since listSalesByInvoice returns Sales object which has itemId
      if (_invoiceType == 'Sale' || _invoiceType == 'بيع') {
        final sales = await SqliteService().listSalesByInvoice(
          widget.invoice!.invoiceId!,
        );
        for (var sale in sales) {
          Item? item;
          try {
            item = items.firstWhere((i) => i.itemId == sale.itemId);
          } catch (_) {
            item = Item(
              itemId: 0,
              itemName: 'Unknown',
              itemType: 'unknown',
              unit: '',
            );
          }

          _lineItems.add({
            'item': item,
            'quantity': sale.quantity,
            'price': sale.unitPrice,
            'total': sale.total,
          });
        }
      } else {
        final purchases = await SqliteService().listPurchasesByInvoice(
          widget.invoice!.invoiceId!,
        );
        for (var purchase in purchases) {
          Item? item;
          try {
            item = items.firstWhere((i) => i.itemId == purchase.itemId);
          } catch (_) {
            item = Item(
              itemId: 0,
              itemName: 'Unknown',
              itemType: 'unknown',
              unit: '',
            );
          }

          _lineItems.add({
            'item': item,
            'quantity': purchase.quantity,
            'price': purchase.unitPrice,
            'total': purchase.total,
          });
        }
      }
    }

    setState(() {
      _customers = customers;
      _allItems = items;
      _isLoading = false;
    });
  }

  double get _grandTotal {
    return _lineItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  void _addItemDialog() {
    final l10n = AppLocalizations.of(context)!;
    Item? selectedItem;
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n.get('add_line_item'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: StatefulBuilder(
              builder:
                  (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Item Dropdown
                      DropdownButtonFormField<Item>(
                        decoration: InputDecoration(
                          labelText: l10n.get('item_label'),
                        ),
                        items:
                            _allItems.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item.itemName),
                              );
                            }).toList(),
                        onChanged: (val) => setState(() => selectedItem = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyController,
                        decoration: InputDecoration(
                          labelText: l10n.get('quantity_label'),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: l10n.get('unit_price_label'),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedItem != null &&
                      qtyController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final total = qty * price;

                    this.setState(() {
                      _lineItems.add({
                        'item': selectedItem,
                        'quantity': qty,
                        'price': price,
                        'total': total,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.get('add')),
              ),
            ],
          ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.get('select_client_msg'),
            ),
          ),
        );
        return;
      }
      if (_lineItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.get('no_items_msg')),
          ),
        );
        return;
      }

      final invoice = Invoice(
        invoiceId: widget.invoice?.invoiceId,
        invoiceType: _invoiceType,
        currency: 'USD', // Default for now
        currencyTransfer: 1.0, // Default
        paymentMethod: _paymentMethod ?? 'cash',
        invoiceDate: _invoiceDate,
        notes: _notes,
        customerId:
            _selectedCustomer!.customerId!, // Force unwrap valid from DB
        total: _grandTotal,
        totalDollar: _grandTotal, // Assuming base currency match for now
        createdAt: widget.invoice?.createdAt,
        updatedAt: DateTime.now(),
      );

      // 1. Insert/Update Invoice
      int invoiceId;
      if (widget.invoice == null) {
        invoiceId = await SqliteService().insertInvoice(invoice);
      } else {
        await SqliteService().updateInvoice(invoice);
        invoiceId = widget.invoice!.invoiceId!;
      }

      // 2. Insert Line Items (Only for new invoices strictly to avoid duplication bugs in MVP)
      if (widget.invoice == null) {
        for (var line in _lineItems) {
          final item = line['item'] as Item;
          final qty = line['quantity'] as double;
          final price = line['price'] as double;
          final total = line['total'] as double;

          if (_invoiceType == 'Sale' || _invoiceType == 'بيع') {
            final sale = Sale(
              invoiceId: invoiceId,
              customerId: _selectedCustomer!.customerId!,
              itemId: item.itemId!,
              quantity: qty,
              unitPrice: price,
              total: total,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await SqliteService().insertSale(sale);
          } else {
            final purchase = Purchase(
              invoiceId: invoiceId,
              customerId: _selectedCustomer!.customerId!,
              itemId: item.itemId!,
              quantity: qty,
              unitPrice: price,
              total: total,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await SqliteService().insertPurchase(purchase);
          }
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          (_invoiceType == 'Sale' || _invoiceType == 'بيع')
              ? l10n.get('sales_invoice')
              : l10n.get('purchase_invoice'),
          style: GoogleFonts.cairo(),
        ),
        backgroundColor:
            (_invoiceType == 'Sale' || _invoiceType == 'بيع')
                ? Colors.green
                : Colors.redAccent,
        elevation: 0,
        actions:
            widget.invoice != null
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(l10n.get('delete_invoice_title')),
                              content: Text(l10n.get('confirm_delete_invoice')),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text(l10n.get('cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    l10n.get('delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await SqliteService().deleteInvoice(
                          widget.invoice!.invoiceId!,
                        );
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ]
                : null,
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
                      // Header Card
                      _buildSectionCard(
                        title: l10n.get('invoice_data'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _invoiceType,
                                    decoration: InputDecoration(
                                      labelText: l10n.get('invoice_type'),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'Sale',
                                        child: Text(l10n.get('sales_filter')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Purchase',
                                        child: Text(
                                          l10n.get('purchases_filter'),
                                        ),
                                      ),
                                    ],
                                    onChanged:
                                        widget.invoice == null
                                            ? (val) => setState(
                                              () => _invoiceType = val!,
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _invoiceDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null)
                                        setState(() => _invoiceDate = picked);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.get('date_label'),
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_invoiceDate),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<Customer>(
                              value: _selectedCustomer,
                              decoration: InputDecoration(
                                labelText: l10n.get('financial_party'),
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
                            const SizedBox(height: 15),
                            TextFormField(
                              initialValue: _notes,
                              decoration: InputDecoration(
                                labelText: l10n.get('note_label'),
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              onChanged: (val) => _notes = val,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Items Section
                      _buildSectionCard(
                        title: l10n.get('items_label'),
                        action: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(l10n.get('add_new_item')),
                          onPressed: _addItemDialog,
                        ),
                        child:
                            _lineItems.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(l10n.get('no_items_added_yet')),
                                  ),
                                )
                                : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _lineItems.length,
                                  separatorBuilder: (ctx, i) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final line = _lineItems[index];
                                    return ListTile(
                                      title: Text(
                                        (line['item'] as Item).itemName,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${line['quantity']} x ${line['price']}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            NumberFormat.currency(
                                              symbol: '',
                                            ).format(line['total']),
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(
                                                () =>
                                                    _lineItems.removeAt(index),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(height: 20),

                      // Totals
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              l10n.get('final_total_label'),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              NumberFormat.currency(
                                symbol: '\$ ',
                              ).format(_grandTotal),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_invoiceType == 'Sale' ||
                                        _invoiceType == 'بيع')
                                    ? Colors.green
                                    : Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _saveInvoice,
                          child: Text(
                            l10n.get('save_invoice'),
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

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
