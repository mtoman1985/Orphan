import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/finance/customer.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await SqliteService().listCustomers();
    setState(() {
      _customers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCustomers = _customers);
      return;
    }
    setState(() {
      _filteredCustomers =
          _customers
              .where(
                (c) =>
                    c.customerName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _showAddEditCustomerDialog([Customer? customer]) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: customer?.customerName);
    final phoneController = TextEditingController(text: customer?.phoneNumber);
    String customerType = customer?.customerType ?? l10n.get('customer_label');

    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              customerType == 'مورد'
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          customer == null
                              ? Icons.person_add_rounded
                              : Icons.edit_rounded,
                          size: 40,
                          color:
                              customerType == 'مورد'
                                  ? Colors.orange.shade800
                                  : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        customer == null
                            ? l10n.get('add_new_customer_supplier')
                            : l10n.get('edit_customer_data'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Customer Type Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap:
                                    () => (context as Element).markNeedsBuild(),
                                // This simple rebuild approach might need StatefulBuilder if we stick to Dialog,
                                // but for dropdown logic we usually need StatefulBuilder anyway.
                                // Let's simplify and keep Dropdown for now in a StatefulBuilder wrapper for the dialog.
                                child: Container(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // We need StatefulBuilder for the dropdown to update properly inside the dialog
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    // Re-implementing with full StatefulBuilder to handle state changes cleanly
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final l10n = AppLocalizations.of(context)!;
              return Directionality(
                textDirection:
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      customerType == 'مورد'
                                          ? Colors.orange.shade50
                                          : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  customerType == 'مورد'
                                      ? Icons.local_shipping_outlined
                                      : Icons.person_outline,
                                  color:
                                      customerType == 'مورد'
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer == null
                                          ? l10n.get('add_new')
                                          : l10n.get('edit_data'),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customerType == l10n.get('supplier_label')
                                          ? l10n.get('supplier_data')
                                          : l10n.get('customer_data'),
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade900,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Type Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _buildTypeOption(
                                  l10n.get('customer_label'),
                                  Icons.person,
                                  customerType == l10n.get('customer_label'),
                                  Colors.blue,
                                  () => setDialogState(
                                    () =>
                                        customerType = l10n.get(
                                          'customer_label',
                                        ),
                                  ),
                                ),
                                _buildTypeOption(
                                  l10n.get('supplier_label'),
                                  Icons.local_shipping,
                                  customerType == l10n.get('supplier_label'),
                                  Colors.orange,
                                  () => setDialogState(
                                    () =>
                                        customerType = l10n.get(
                                          'supplier_label',
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Inputs
                          _buildModernTextField(
                            controller: nameController,
                            label: l10n.get('full_name_label'),
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: phoneController,
                            label: l10n.get('phone_number_label'),
                            icon: Icons.phone_android_outlined,
                            isDigits: true,
                          ),
                          const SizedBox(height: 32),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.get('cancel'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (nameController.text.isEmpty) return;

                                    final newCustomer = Customer(
                                      customerId: customer?.customerId,
                                      customerName: nameController.text,
                                      phoneNumber: phoneController.text,
                                      customerType: customerType,
                                      createdAt: customer?.createdAt,
                                      updatedAt: DateTime.now(),
                                    );

                                    if (customer == null) {
                                      await SqliteService().insertCustomer(
                                        newCustomer,
                                      );
                                    } else {
                                      await SqliteService().updateCustomer(
                                        newCustomer,
                                      );
                                    }

                                    // Reload customers first
                                    await _loadCustomers();

                                    // Then close the dialog
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        customerType == 'مورد'
                                            ? Colors.orange.shade700
                                            : Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 2,
                                    shadowColor: (customerType == 'مورد'
                                            ? Colors.orange
                                            : Colors.blue)
                                        .withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.get('save_data'),
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
            },
          ),
    );
  }

  Widget _buildTypeOption(
    String label,
    IconData icon,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDigits = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isDigits ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.get('manage_customers_suppliers'),
          style: GoogleFonts.cairo(),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCustomers,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.get('search_customer_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCustomers.isEmpty
                    ? Center(
                      child: Text(
                        l10n.get('no_data_found'),
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          delay: Duration(milliseconds: index * 50),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    customer.customerType ==
                                            l10n.get('supplier_label')
                                        ? Colors.orange.shade100
                                        : Colors.blue.shade100,
                                child: Icon(
                                  customer.customerType ==
                                          l10n.get('supplier_label')
                                      ? Icons.local_shipping
                                      : Icons.person,
                                  color:
                                      customer.customerType ==
                                              l10n.get('supplier_label')
                                          ? Colors.orange
                                          : Colors.blue,
                                ),
                              ),
                              title: Text(
                                customer.customerName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${customer.customerType} - ${customer.phoneNumber ?? l10n.get('no_phone_label')}',
                                style: GoogleFonts.cairo(),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _showAddEditCustomerDialog(
                                          customer,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          final l10n =
                                              AppLocalizations.of(context)!;
                                          return AlertDialog(
                                            title: Text(
                                              l10n.get('confirm_delete_title'),
                                            ),
                                            content: Text(
                                              l10n.get(
                                                'confirm_delete_customer_msg',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(l10n.get('cancel')),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  l10n.get('delete'),
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        await SqliteService().deleteCustomer(
                                          customer.customerId!,
                                        );
                                        _loadCustomers();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCustomerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
