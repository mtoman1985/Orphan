import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/sqlite_service.dart';
import 'customers_page.dart';
import 'items_page.dart';
import 'invoices_page.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import 'payments_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  Map<String, dynamic> _stats = {
    'customersCount': 0,
    'itemsCount': 0,
    'totalSales': 0.0,
    'totalPurchases': 0.0,
    'invoicesCount': 0,
  };
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SqliteService().getFinanceStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.getKey('financial_system_title'),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          l10n.getKey('finance_control_panel'),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadStats,
                      tooltip: l10n.getKey('refresh_data'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats Overview (New Section)
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        l10n.getKey('total_sales'),
                        '${_stats['totalSales'].toStringAsFixed(2)}', // Currency formatting
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        l10n.getKey('total_purchases'),
                        '${_stats['totalPurchases'].toStringAsFixed(2)}',
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        l10n.getKey('net_balance'),
                        '${(_stats['totalSales'] - _stats['totalPurchases']).toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                l10n.getKey('quick_access'),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Action Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.people_outline,
                      title: l10n.getKey('customers_and_suppliers'),
                      subtitle:
                          '${_stats['customersCount']} ${l10n.getKey('registered_count')}',
                      color: Colors.blue,
                      delay: 100,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomersPage(),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.getKey('inventory_and_items'),
                      subtitle:
                          '${_stats['itemsCount']} ${l10n.getKey('items_count_label')}',
                      color: Colors.orange,
                      delay: 200,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ItemsPage(),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.getKey('invoices_log'),
                      subtitle:
                          '${_stats['invoicesCount']} ${l10n.getKey('invoices_count_label')}',
                      color: Colors.purple,
                      delay: 300,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InvoicesPage(),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.add_shopping_cart_rounded,
                      title: l10n.getKey('purchase_invoice'),
                      subtitle: l10n.getKey('register_new_entry'),
                      color: Colors.red,
                      delay: 400,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const InvoicesPage(
                                  initialFilter: 'Purchase',
                                ),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.point_of_sale_rounded,
                      title: l10n.getKey('sales_invoice'),
                      subtitle: l10n.getKey('register_new_sale'),
                      color: Colors.green,
                      delay: 500,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const InvoicesPage(initialFilter: 'Sale'),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.payments_outlined,
                      title: l10n.getKey('finance_payments'),
                      subtitle: l10n.getKey('finance_receipts_and_vouchers'),
                      color: Colors.teal,
                      delay: 600,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentsPage(),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ), // Smaller icon
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
