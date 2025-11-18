import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/database_service.dart';

class EditChildPage extends StatefulWidget {
  final Child child;

  const EditChildPage({super.key, required this.child});

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  late TextEditingController _fullNameController;
  late TextEditingController _childIdNumberController;
  late TextEditingController _fatherNameController;
  late TextEditingController _fatherIdNumberController;
  late TextEditingController _motherNameController;
  late TextEditingController _motherIdNumberController;
  late TextEditingController _disabilityTypeController;
  
  late DatabaseService _dbService;
  String? _selectedMotherStatus;
  String? _selectedHealthStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    
    _fullNameController = TextEditingController(text: widget.child.fullName);
    _childIdNumberController = TextEditingController(text: widget.child.childIdNumber);
    _fatherNameController = TextEditingController(text: widget.child.fatherName);
    _fatherIdNumberController = TextEditingController(text: widget.child.fatherIdNumber);
    _motherNameController = TextEditingController(text: widget.child.motherName);
    _motherIdNumberController = TextEditingController(text: widget.child.motherIdNumber);
    _disabilityTypeController = TextEditingController(text: widget.child.disabilityType ?? '');
    
    _selectedMotherStatus = widget.child.motherStatus;
    _selectedHealthStatus = widget.child.healthStatus;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _childIdNumberController.dispose();
    _fatherNameController.dispose();
    _fatherIdNumberController.dispose();
    _motherNameController.dispose();
    _motherIdNumberController.dispose();
    _disabilityTypeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_fullNameController.text.isEmpty || _childIdNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedChild = Child(
        id: widget.child.id,
        fullName: _fullNameController.text,
        dateOfBirth: widget.child.dateOfBirth,
        childIdNumber: _childIdNumberController.text,
        fatherName: _fatherNameController.text,
        fatherIdNumber: _fatherIdNumberController.text,
        motherName: _motherNameController.text,
        motherIdNumber: _motherIdNumberController.text,
        motherStatus: _selectedMotherStatus ?? 'Alive',
        healthStatus: _selectedHealthStatus ?? 'Healthy',
        disabilityType: _disabilityTypeController.text.isEmpty ? null : _disabilityTypeController.text,
        siblings: widget.child.siblings,
        documents: widget.child.documents,
        sponsor: widget.child.sponsor,
        createdAt: widget.child.createdAt,
      );

      await _dbService.updateChild(updatedChild);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child updated successfully')),
        );
        Navigator.pop(context, updatedChild);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Child Information'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter child full name',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Child ID Number
                  TextField(
                    controller: _childIdNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Child ID Number *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter child ID number',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Father Information
                  Text(
                    'Father Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fatherNameController,
                    decoration: const InputDecoration(
                      labelText: 'Father Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fatherIdNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Father ID Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mother Information
                  Text(
                    'Mother Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _motherNameController,
                    decoration: const InputDecoration(
                      labelText: 'Mother Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _motherIdNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Mother ID Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMotherStatus,
                    decoration: const InputDecoration(
                      labelText: 'Mother Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Alive', child: Text('Alive')),
                      DropdownMenuItem(value: 'Deceased', child: Text('Deceased')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMotherStatus = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Health Information
                  Text(
                    'Health Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedHealthStatus,
                    decoration: const InputDecoration(
                      labelText: 'Health Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                      DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                      DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedHealthStatus = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _disabilityTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Disability Type (if applicable)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
