import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/finance/item.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    await SqliteService().seedItems();
    final items = await SqliteService().listItems();
    setState(() {
      _items = items;
      _filteredItems = items;
      _isLoading = false;
    });
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() => _filteredItems = _items);
      return;
    }
    setState(() {
      _filteredItems =
          _items
              .where(
                (i) => i.itemName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _showAddEditItemDialog([Item? item]) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: item?.itemName);
    final unitController = TextEditingController(text: item?.unit);
    String itemType = item?.itemType ?? l10n.get('item_type_materials');

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
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
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.orange.shade700,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item == null
                                          ? l10n.get('add_new')
                                          : l10n.get('edit_item'),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.get('item_details'),
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

                          // Type Selector (Modern Tabs)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTypeChip(
                                  l10n.get('item_type_materials'),
                                  itemType == l10n.get('item_type_materials'),
                                  () => setDialogState(
                                    () =>
                                        itemType = l10n.get(
                                          'item_type_materials',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildTypeChip(
                                  l10n.get('item_type_supplies'),
                                  itemType == l10n.get('item_type_supplies'),
                                  () => setDialogState(
                                    () =>
                                        itemType = l10n.get(
                                          'item_type_supplies',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildTypeChip(
                                  l10n.get('item_type_service'),
                                  itemType == l10n.get('item_type_service'),
                                  () => setDialogState(
                                    () =>
                                        itemType = l10n.get(
                                          'item_type_service',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildTypeChip(
                                  l10n.get('item_type_product'),
                                  itemType == l10n.get('item_type_product'),
                                  () => setDialogState(
                                    () =>
                                        itemType = l10n.get(
                                          'item_type_product',
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
                            label: l10n.get('item_name_label'),
                            icon: Icons.label_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: unitController,
                            label: l10n.get('unit_label'),
                            icon: Icons.scale_outlined,
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
                                    if (nameController.text.isEmpty ||
                                        unitController.text.isEmpty)
                                      return;

                                    final newItem = Item(
                                      itemId: item?.itemId,
                                      itemName: nameController.text,
                                      unit: unitController.text,
                                      itemType: itemType,
                                      createdAt: item?.createdAt,
                                      updatedAt: DateTime.now(),
                                    );

                                    if (item == null) {
                                      await SqliteService().insertItem(newItem);
                                    } else {
                                      await SqliteService().updateItem(newItem);
                                    }

                                    // Reload items first
                                    await _loadItems();

                                    // Then close the dialog
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 2,
                                    shadowColor: Colors.orange.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.get('save_item'),
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

  Widget _buildTypeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange.shade300 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.orange.shade800 : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
              borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
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
        title: Text(l10n.get('manage_items'), style: GoogleFonts.cairo()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                labelText: l10n.get('search_item_hint'),
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
                    : _filteredItems.isEmpty
                    ? Center(
                      child: Text(
                        l10n.get('no_items_found'),
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
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
                                backgroundColor: Colors.orange.shade100,
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.orange,
                                ),
                              ),
                              title: Text(
                                item.itemName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item.itemType} - ${item.unit}',
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
                                        () => _showAddEditItemDialog(item),
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
                                                'confirm_delete_item_msg',
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
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        await SqliteService().deleteItem(
                                          item.itemId!,
                                        );
                                        _loadItems();
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
        onPressed: () => _showAddEditItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
