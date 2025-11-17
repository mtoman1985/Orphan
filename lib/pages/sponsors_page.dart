import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sponsor.dart';
import '../models/child.dart';
import '../services/database_service.dart';

class SponsorsPage extends StatefulWidget {
  final String? childId;

  const SponsorsPage({super.key, this.childId});

  @override
  State<SponsorsPage> createState() => _SponsorsPageState();
}

class _SponsorsPageState extends State<SponsorsPage> {
  late DatabaseService _dbService;
  late Future<List<Sponsor>> _sponsorsFuture;
  Sponsor? _selectedSponsor;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    _sponsorsFuture = _dbService.getAllSponsors();
  }

  void _openAddSponsorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Sponsor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Sponsor Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Monthly Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter sponsor name')),
                );
                return;
              }

              final sponsor = Sponsor(
                id: const Uuid().v4(),
                name: nameController.text,
                amount: double.tryParse(amountController.text) ?? 0.0,
                startDate: DateTime.now(),
                email: emailController.text.isEmpty ? null : emailController.text,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
              );

              await _dbService.insertSponsor(sponsor);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _sponsorsFuture = _dbService.getAllSponsors();
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _linkSponsorToChild(Sponsor sponsor) async {
    if (widget.childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No child selected')),
      );
      return;
    }

    await _dbService.linkSponsorToChild(widget.childId!, sponsor.id);
    if (mounted) {
      Navigator.pop(context, sponsor);
    }
  }

  void _deleteSponsor(String sponsorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sponsor'),
        content: const Text('Are you sure you want to delete this sponsor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteSponsor(sponsorId);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _sponsorsFuture = _dbService.getAllSponsors();
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsors Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddSponsorDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Sponsor>>(
        future: _sponsorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sponsors = snapshot.data ?? [];

          if (sponsors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No sponsors found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openAddSponsorDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Sponsor'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sponsors.length,
            itemBuilder: (context, index) {
              final sponsor = sponsors[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(sponsor.name[0].toUpperCase()),
                  ),
                  title: Text(sponsor.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sponsor.email != null) Text('Email: ${sponsor.email}'),
                      if (sponsor.phone != null) Text('Phone: ${sponsor.phone}'),
                      Text('Amount: \$${sponsor.amount.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      if (widget.childId != null)
                        PopupMenuItem(
                          onTap: () => _linkSponsorToChild(sponsor),
                          child: const Text('Link to Child'),
                        ),
                      PopupMenuItem(
                        onTap: () => _deleteSponsor(sponsor.id),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: widget.childId != null
                      ? () => _linkSponsorToChild(sponsor)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
