import 'package:flutter/material.dart';
import '../../models/sponsor.dart';
import '../../services/sqlite_service.dart';
import '../../models/child.dart';
import '../../models/payment.dart';
import '../registration/registration_form.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SponsorDetailPage extends StatefulWidget {
  final String sponsorId;
  const SponsorDetailPage({super.key, required this.sponsorId});

  @override
  State<SponsorDetailPage> createState() => _SponsorDetailPageState();
}

class _SponsorDetailPageState extends State<SponsorDetailPage> {
  Sponsor? sponsor;
  List<Child> ongoingChildren = [];
  List<Child> endedChildren = [];
  List<Payment> payments = [];
  Map<String, double> totalsByCurrency = {};
  Map<String, double> childTotals = {};
  bool isLoading = true;
  bool isSelectionMode = false;
  Set<String> selectedChildrenIds = {};

  @override
  void initState() {
    super.initState();
    _loadSponsorDetails();
  }

  Future<void> _loadSponsorDetails() async {
    setState(() => isLoading = true);
    final db = SqliteService();
    final s = await db.getSponsorById(widget.sponsorId);

    final children = await db.getChildrenBySponsorId(widget.sponsorId);
    final List<Child> ongoing = [];
    final List<Child> ended = [];

    for (final c in children) {
      if (c.sponsor?.isOngoing == true) {
        ongoing.add(c);
      } else {
        ended.add(c);
      }
    }

    // Get payments for this sponsor (new style)
    List<Payment> sponsorPayments = await db.listPaymentsBySponsorId(
      widget.sponsorId,
    );

    // Legacy/Fallback: check payments of children that don't have the sponsorId set yet
    for (final c in children) {
      final childPayments = await db.listPayments(childId: c.id);
      for (final cp in childPayments) {
        if (cp.sponsorId == null) {
          // Check for duplication just in case
          if (!sponsorPayments.any((p) => p.id == cp.id)) {
            sponsorPayments.add(cp);
          }
        }
      }
    }

    // Sort all combined payments by date descending
    sponsorPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));

    final Map<String, double> totals = {};
    final Map<String, double> cTotals = {};

    for (final p in sponsorPayments) {
      final cur = p.currency ?? s?.currency ?? 'شيكل';
      final amnt = p.amount;
      totals[cur] = (totals[cur] ?? 0) + amnt;

      // Calculate total per child
      cTotals[p.childId] = (cTotals[p.childId] ?? 0) + amnt;
    }

    setState(() {
      sponsor = s;
      ongoingChildren = ongoing;
      endedChildren = ended;
      payments = sponsorPayments;
      totalsByCurrency = totals;
      childTotals = cTotals;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (sponsor == null) {
      return const Scaffold(body: Center(child: Text('Sponsor not found')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'تحديد للدفع' : 'تفاصيل الكفيل'),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.payments_outlined),
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                  selectedChildrenIds.clear();
                });
              },
              tooltip: 'دفع جماعي',
            ),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedChildrenIds.clear();
                });
              },
              tooltip: 'إلغاء التحديد',
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showManageChildrenDialog,
            tooltip: 'إضافة يتيم للكفالة',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // --- Redesigned Sponsor Info Card ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade900, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade900.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Decorative background pattern
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Icon(
                            Icons.volunteer_activism,
                            size: 150,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 30,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.blue.shade900,
                                      size: 35,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sponsor!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            sponsor!.isOngoing
                                                ? 'كفالة مستمرة'
                                                : 'انتهت الكفالة',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSponsorDetailItem(
                                    Icons.currency_exchange,
                                    'العملة',
                                    sponsor!.currency,
                                  ),
                                  _buildSponsorDetailItem(
                                    Icons.calendar_today,
                                    'تاريخ البدء',
                                    sponsor!.startDate.toIso8601String().split(
                                      'T',
                                    )[0],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 20),
                              const Text(
                                'إجمالي الأموال المدفوعة:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (totalsByCurrency.isEmpty)
                                const Text(
                                  '0.00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 16,
                                  children:
                                      totalsByCurrency.entries
                                          .map(
                                            (e) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${e.value.toStringAsFixed(2)} ${e.key}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(
                      'الأيتام المكفولون (كفالة مستمرة):',
                      ongoingChildren.length,
                    ),
                    if (isSelectionMode && ongoingChildren.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (selectedChildrenIds.length ==
                                ongoingChildren.length) {
                              selectedChildrenIds.clear();
                            } else {
                              selectedChildrenIds =
                                  ongoingChildren.map((c) => c.id).toSet();
                            }
                          });
                        },
                        child: Text(
                          selectedChildrenIds.length == ongoingChildren.length
                              ? 'إلغاء الكل'
                              : 'تحديد الكل',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (ongoingChildren.isEmpty)
                  _buildEmptyState('لا يوجد أيتام بكفالة مستمرة حالياً')
                else
                  ...ongoingChildren.map((c) => _buildChildCard(c, true)),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  'الأيتام الذين انتهت كفالتهم:',
                  endedChildren.length,
                ),
                const SizedBox(height: 8),
                if (endedChildren.isEmpty)
                  _buildEmptyState('لا يوجد أيتام بكفالة منتهية')
                else
                  ...endedChildren.map((c) => _buildChildCard(c, false)),

                const SizedBox(height: 32),
                _buildSectionHeader(
                  'مجموع الأموال المدفوعة:',
                  totalsByCurrency.length,
                ),
                const SizedBox(height: 12),
                if (totalsByCurrency.isEmpty)
                  _buildEmptyState('لا توجد دفعات مسجلة بعد')
                else
                  ...totalsByCurrency.entries.map(
                    (entry) => _buildTotalCard(entry.key, entry.value),
                  ),

                const SizedBox(height: 32),
                _buildSectionHeader('سجل الدفعات الأخيرة:', payments.length),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  _buildEmptyState('لا توجد دفعات مسجلة')
                else
                  ...payments.take(20).map((p) => _buildPaymentRow(p)),

                if (payments.length > 20)
                  TextButton(
                    onPressed: () {
                      // Show all payments in a dialog or separate page
                    },
                    child: const Text('عرض الكل'),
                  ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
          if (isSelectionMode && selectedChildrenIds.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: Offset.zero,
                child: FloatingActionButton.extended(
                  onPressed: _showBulkPaymentDialog,
                  label: Text(
                    'تسجيل دفعة لـ ${selectedChildrenIds.length} أيتام',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.add_card),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChildCard(Child c, bool isOngoing) {
    final isSelected = selectedChildrenIds.contains(c.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected ? Colors.blue : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            isSelected
                ? const BorderSide(color: Colors.blue, width: 2)
                : BorderSide.none,
      ),
      child: ListTile(
        leading:
            isSelectionMode
                ? Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedChildrenIds.add(c.id);
                      } else {
                        selectedChildrenIds.remove(c.id);
                      }
                    });
                  },
                )
                : CircleAvatar(
                  backgroundColor:
                      isOngoing ? Colors.green.shade50 : Colors.grey.shade50,
                  child: Icon(
                    Icons.person,
                    color:
                        isOngoing
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                  ),
                ),
        title: Text(
          c.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الكفالة الشهرية: ${c.sponsor?.amount ?? 0} ${c.sponsor?.currency ?? ''}',
            ),
            Text(
              'إجمالي المستلم: ${childTotals[c.id]?.toStringAsFixed(2) ?? "0.00"} ${c.sponsor?.currency ?? ''}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (!isOngoing && (c.sponsor?.endReason ?? '').isNotEmpty)
              Text('سبب الانتهاء: ${c.sponsor!.endReason}'),
            if (isOngoing) _buildLastPaymentStatus(c.id),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOngoing && !isSelectionMode)
              IconButton(
                icon: const Icon(Icons.add_card, color: Colors.green),
                tooltip: 'تسجيل دفعة',
                onPressed: () => _showAddPaymentDialog(c),
              ),
            if (isOngoing && !isSelectionMode)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                tooltip: 'إنهاء الكفالة',
                onPressed: () => _showEndSponsorshipConfirm(c),
              ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
        onTap:
            isSelectionMode
                ? () {
                  setState(() {
                    if (isSelected) {
                      selectedChildrenIds.remove(c.id);
                    } else {
                      selectedChildrenIds.add(c.id);
                    }
                  });
                }
                : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RegistrationForm(child: c),
                    ),
                  );
                  _loadSponsorDetails();
                },
      ),
    );
  }

  void _showBulkPaymentDialog() {
    final amountCtl = TextEditingController();
    // Calculate default total amount
    double totalDefault = 0;
    for (var id in selectedChildrenIds) {
      final child = ongoingChildren.firstWhere((c) => c.id == id);
      totalDefault += child.sponsor?.amount ?? 0;
    }
    amountCtl.text = totalDefault.toString();

    final dateCtl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final noteCtl = TextEditingController(text: 'دفعة جماعية');

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('تسجيل دفعة لـ ${selectedChildrenIds.length} أيتام'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'سيتم توزيع المبلغ بالتساوي أو حسب مبالغ كفالتهم؟',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ الإجمالي',
                        border: OutlineInputBorder(),
                        suffixText: 'شيكل', // Default
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateCtl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'تاريخ الدفع',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              dateCtl.text =
                                  picked.toIso8601String().split('T')[0];
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة',
                        border: OutlineInputBorder(),
                      ),
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
                  onPressed: () async {
                    if (amountCtl.text.isEmpty) return;
                    final totalAmount = double.parse(amountCtl.text);
                    final paidAt = DateTime.parse(dateCtl.text);
                    final note = noteCtl.text;

                    final db = SqliteService();
                    final amountPerChild =
                        totalAmount / selectedChildrenIds.length;

                    for (final childId in selectedChildrenIds) {
                      final currentUser =
                          Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).currentUser;
                      await db.insertPayment(
                        Payment(
                          id:
                              'pay_${childId}_${DateTime.now().millisecondsSinceEpoch}_${selectedChildrenIds.toList().indexOf(childId)}',
                          childId: childId,
                          sponsorId: widget.sponsorId,
                          amount: amountPerChild,
                          currency: sponsor?.currency ?? 'شيكل',
                          paidAt: paidAt,
                          note: note,
                          createdBy:
                              currentUser?.fullName ??
                              currentUser?.username ??
                              'System',
                          updatedBy:
                              currentUser?.fullName ??
                              currentUser?.username ??
                              'System',
                        ),
                      );
                    }

                    setState(() {
                      isSelectionMode = false;
                      selectedChildrenIds.clear();
                    });
                    await _loadSponsorDetails();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل الدفعات بنجاح')),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
    );
  }

  void _showAddPaymentDialog(Child child) {
    final amountCtl = TextEditingController(
      text: (child.sponsor?.amount ?? 0).toString(),
    );
    final dateCtl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final noteCtl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('تسجيل دفعة لـ ${child.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (p != null) {
                            dateCtl.text = p.toIso8601String().split('T')[0];
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (amountCtl.text.isEmpty) return;
                    final currentUser =
                        Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).currentUser;
                    final p = Payment(
                      id:
                          'pay_${child.id}_${DateTime.now().millisecondsSinceEpoch}',
                      childId: child.id,
                      sponsorId: widget.sponsorId,
                      amount: double.parse(amountCtl.text),
                      currency:
                          child.sponsor?.currency ??
                          sponsor?.currency ??
                          'شيكل',
                      paidAt: DateTime.parse(dateCtl.text),
                      note: noteCtl.text,
                      createdBy:
                          currentUser?.fullName ??
                          currentUser?.username ??
                          'System',
                      updatedBy:
                          currentUser?.fullName ??
                          currentUser?.username ??
                          'System',
                    );
                    await SqliteService().insertPayment(p);
                    _loadSponsorDetails();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showManageChildrenDialog() async {
    final searchCtl = TextEditingController();
    List<Child> allChildren = [];
    List<Child> filteredChildren = [];

    // Track which children are currently sponsored by THIS sponsor
    final Set<String> initiallySponsoredIds =
        ongoingChildren.map((c) => c.id).toSet();
    final Set<String> currentSelections = Set.from(initiallySponsoredIds);

    setState(() => isLoading = true);
    allChildren = await SqliteService().listChildren();
    allChildren.sort((a, b) => a.fullName.compareTo(b.fullName));
    filteredChildren = List.from(allChildren);
    setState(() => isLoading = false);

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('إدارة أيتام الكفيل'),
                    content: SizedBox(
                      width: 500,
                      height: 600,
                      child: Column(
                        children: [
                          TextField(
                            controller: searchCtl,
                            decoration: InputDecoration(
                              hintText: 'بحث بالاسم أو رقم الهوية...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                filteredChildren =
                                    allChildren.where((c) {
                                      final query = val.toLowerCase();
                                      return c.fullName.toLowerCase().contains(
                                            query,
                                          ) ||
                                          (c.nationalId?.contains(query) ??
                                              false) ||
                                          (c.childIdNumber.contains(query));
                                    }).toList();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildChipStyle(
                                'كفالة حالية',
                                Colors.blue.shade100,
                                Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              _buildChipStyle(
                                'كفالة أخرى',
                                Colors.orange.shade100,
                                Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              _buildChipStyle(
                                'بدون كفالة',
                                Colors.grey.shade100,
                                Colors.grey.shade800,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredChildren.length,
                              itemBuilder: (context, index) {
                                final child = filteredChildren[index];
                                final isInitiallyMine = initiallySponsoredIds
                                    .contains(child.id);
                                final isCurrentlySelected = currentSelections
                                    .contains(child.id);

                                // Determine relationship status
                                bool isSponByOthers =
                                    child.sponsor != null &&
                                    child.sponsor?.linkedSponsorId !=
                                        widget.sponsorId &&
                                    child.sponsor?.id != widget.sponsorId;

                                Color? bgColor;
                                if (isCurrentlySelected) {
                                  bgColor = Colors.blue.shade50;
                                } else if (isSponByOthers) {
                                  bgColor = Colors.orange.shade50;
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        isCurrentlySelected
                                            ? Border.all(
                                              color: Colors.blue.shade300,
                                            )
                                            : null,
                                  ),
                                  child: CheckboxListTile(
                                    value: isCurrentlySelected,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          currentSelections.add(child.id);
                                        } else {
                                          currentSelections.remove(child.id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      child.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isSponByOthers
                                          ? 'مكفول لدى: ${child.sponsor?.name}'
                                          : isInitiallyMine
                                          ? 'مكفول حالياً لدى هذا الكفيل'
                                          : 'غير مكفول',
                                      style: TextStyle(
                                        color:
                                            isSponByOthers
                                                ? Colors.orange.shade900
                                                : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        child.firstName[0],
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveManagedChildren(
                            initiallySponsoredIds,
                            currentSelections,
                            allChildren,
                          );
                        },
                        child: const Text('حفظ التغييرات'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildChipStyle(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _saveManagedChildren(
    Set<String> initial,
    Set<String> current,
    List<Child> all,
  ) async {
    setState(() => isLoading = true);
    final db = SqliteService();
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    final executorName =
        currentUser?.fullName ?? currentUser?.username ?? 'System';

    // 1. Identification of added children
    final addedIds = current.difference(initial);
    // 2. Identification of removed children
    final removedIds = initial.difference(current);
    String? endReason;
    if (removedIds.isNotEmpty) {
      final reasonController = TextEditingController();
      endReason = await showDialog<String>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('سبب انتهاء الكفالة'),
              content: TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب انتهاء الكفالة',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, reasonController.text.trim());
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
      );
      if (endReason == null) return;
    }

    int count = 0;

    // Process removals
    for (final id in removedIds) {
      final child = all.firstWhere((c) => c.id == id);
      if (child.sponsor != null) {
        child.sponsor!.isOngoing = false;
        child.sponsor!.endDate = DateTime.now();
        child.sponsor!.endReason = endReason;
        child.updatedBy = executorName;
        await db.insertChild(
          child,
        ); // This uses updateChildSponsor logic effectively
        count++;
      }
    }

    // Process additions
    for (final id in addedIds) {
      final child = all.firstWhere((c) => c.id == id);
      final newSponsorship = Sponsor(
        id: widget.sponsorId,
        linkedSponsorId: widget.sponsorId,
        name: sponsor!.name,
        amount: sponsor!.amount,
        currency: sponsor!.currency,
        startDate: DateTime.now(),
        isOngoing: true,
      );
      child.sponsor = newSponsorship;
      child.sponsorLinkedAt = DateTime.now();
      child.updatedAt = DateTime.now();
      child.updatedBy = executorName;
      await db.insertChild(child);
      count++;
    }

    await _loadSponsorDetails();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث بيانات $count أيتام بنجاح')),
    );
  }

  void _showEndSponsorshipConfirm(Child child) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد إنهاء الكفالة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('هل أنت متأكد من إنهاء كفالة اليتيم ${child.fullName}؟'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'سبب انتهاء الكفالة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) return;
                    await _endSponsorship(child, reasonController.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'إنهاء الكفالة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _endSponsorship(Child child, String endReason) async {
    if (child.sponsor == null) return;
    child.sponsor!.isOngoing = false;
    child.sponsor!.endDate = DateTime.now();
    child.sponsor!.endReason = endReason;

    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    final executorName =
        currentUser?.fullName ?? currentUser?.username ?? 'System';
    child.updatedBy = executorName;

    final db = SqliteService();
    await db.insertChild(child);
    _loadSponsorDetails(); // REFRESH
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إنهاء الكفالة')));
  }

  Widget _buildLastPaymentStatus(String childId) {
    final childPayments = payments.where((p) => p.childId == childId).toList();
    if (childPayments.isEmpty) {
      return const Text(
        'لم يتم الدفع بعد',
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Payments are already sorted desc
    final lastPay = childPayments.first;
    final isRecent =
        lastPay.paidAt.year == DateTime.now().year &&
        lastPay.paidAt.month == DateTime.now().month;

    return Text(
      'آخر دفعة: ${lastPay.paidAt.toIso8601String().split('T')[0]}',
      style: TextStyle(
        fontSize: 12,
        color: isRecent ? Colors.green.shade700 : Colors.grey.shade600,
        fontWeight: isRecent ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPaymentRow(Payment p) {
    // Find child name
    String childName = 'يتيم مجهول';
    final allPossible = [...ongoingChildren, ...endedChildren];
    final c = allPossible.where((child) => child.id == p.childId).toList();
    if (c.isNotEmpty) {
      childName = c.first.fullName;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.history, size: 20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              childName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${p.amount.toStringAsFixed(2)} ${p.currency}',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${p.paidAt.toIso8601String().split('T')[0]} ${p.note != null ? '- ${p.note}' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTotalCard(String currency, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currency,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
