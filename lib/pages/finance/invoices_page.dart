import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/finance/invoice.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import 'invoice_form_page.dart';

class InvoicesPage extends StatefulWidget {
  final String? initialFilter;
  const InvoicesPage({super.key, this.initialFilter});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  late String _filterType;
  final TextEditingController _searchController = TextEditingController();

  // Summary vars
  double _totalSales = 0;
  double _totalPurchases = 0;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialFilter ?? 'All';
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final invoices = await SqliteService().listInvoices();

    // Calculate totals
    double sales = 0;
    double purchases = 0;
    for (var inv in invoices) {
      if (inv.invoiceType == 'Sale' || inv.invoiceType == 'بيع') {
        sales += inv.total;
      } else if (inv.invoiceType == 'Purchase' || inv.invoiceType == 'شراء') {
        purchases += inv.total;
      }
    }

    setState(() {
      _invoices = invoices;
      _totalSales = sales;
      _totalPurchases = purchases;
      _isLoading = false;
    });
    _filterInvoices('');
  }

  void _filterInvoices(String query) {
    setState(() {
      _filteredInvoices =
          _invoices.where((inv) {
            final matchesQuery =
                inv.invoiceId.toString().contains(query) ||
                (inv.notes != null &&
                    inv.notes!.toLowerCase().contains(query.toLowerCase()));

            final matchesType =
                _filterType == 'All' ||
                (_filterType == 'Sale' &&
                    (inv.invoiceType == 'Sale' || inv.invoiceType == 'بيع')) ||
                (_filterType == 'Purchase' &&
                    (inv.invoiceType == 'Purchase' ||
                        inv.invoiceType == 'شراء'));

            return matchesQuery && matchesType;
          }).toList();
    });
  }

  void _onTypeFilterChanged(String? type) {
    if (type != null) {
      setState(() {
        _filterType = type;
        _filterInvoices(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.get('manage_invoices'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
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
                      l10n.get('total_sales_label'),
                      _totalSales,
                      Colors.greenAccent,
                    ),
                    Container(height: 40, width: 1, color: Colors.white30),
                    _buildSummaryItem(
                      l10n.get('total_purchases_label'),
                      _totalPurchases,
                      Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search and Filter
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterInvoices,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: l10n.get('search_invoices_hint'),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterType,
                          dropdownColor: Colors.indigo,
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
                              value: 'Sale',
                              child: Text(
                                l10n.get('sales_filter'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Purchase',
                              child: Text(
                                l10n.get('purchases_filter'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: _onTypeFilterChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Invoice List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInvoices.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.get('no_invoices_found'),
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
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        final isSale = invoice.invoiceType == 'بيع';
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildInvoiceCard(invoice, isSale, l10n),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoiceFormPage()),
          );
          _loadInvoices(); // Refresh after return
        },
        icon: const Icon(Icons.add),
        label: Text(
          l10n.get('new_invoice'),
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

  Widget _buildInvoiceCard(
    Invoice invoice,
    bool isSale,
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
                builder: (context) => InvoiceFormPage(invoice: invoice),
              ),
            );
            _loadInvoices();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        isSale
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSale ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isSale ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.get('invoice_label')} #${invoice.invoiceId}',
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
                            // We need to fetch customer name properly. For now showing ID helper
                            // In real app, we would join tables or fetch name.
                            // Assuming we can pass customer map or load it.
                            '${l10n.get('customer_prefix')} #${invoice.customerId}',
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
                          Text(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(invoice.invoiceDate),
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
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: '',
                        decimalDigits: 0,
                      ).format(invoice.total),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSale ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSale
                            ? l10n.get('sales_filter')
                            : l10n.get('purchases_filter'),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: isSale ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
