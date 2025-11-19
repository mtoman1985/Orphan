import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/document.dart';
import '../models/sponsor.dart';
import '../services/storage_service.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  // Page 1
  final _fullNameCtl = TextEditingController();
  DateTime? _dob;
  final _childIdCtl = TextEditingController();
  final _fatherNameCtl = TextEditingController();
  final _fatherIdCtl = TextEditingController();
  final _motherNameCtl = TextEditingController();
  final _motherIdCtl = TextEditingController();
  String _motherStatus = 'Alive';

  // Page 2
  String _healthStatus = 'Healthy';
  final _disabilityCtl = TextEditingController();
  final List<Map<String, String>> _siblings = [];

  // Page 3 documents
  final List<Document> _documents = [];

  // Page 4 sponsor
  final _sponsorNameCtl = TextEditingController();
  final _sponsorAmountCtl = TextEditingController();
  DateTime? _sponsorStart;
  final _relationshipCtl = TextEditingController();

  int _currentStep = 0;

  Future<void> _pickFile(String type) async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (res == null) return;
    final path = res.files.single.path;
    if (path == null) return;
    final file = File(path);
    final doc = await _storage.saveFile(file, type: type);
    setState(() => _documents.add(doc));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = Uuid().v4();
    final child = Child(
      id: id,
      fullName: _fullNameCtl.text.trim(),
      dateOfBirth: _dob,
      childIdNumber: _childIdCtl.text.trim(),
      fatherName: _fatherNameCtl.text.trim(),
      fatherIdNumber: _fatherIdCtl.text.trim(),
      motherName: _motherNameCtl.text.trim(),
      motherIdNumber: _motherIdCtl.text.trim(),
      motherStatus: _motherStatus,
      healthStatus: _healthStatus,
      disabilityType:
          _disabilityCtl.text.trim().isEmpty
              ? null
              : _disabilityCtl.text.trim(),
      siblings: _siblings,
      documents: _documents,
      sponsor:
          _sponsorNameCtl.text.trim().isEmpty
              ? null
              : Sponsor(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _sponsorNameCtl.text.trim(),
                amount: double.tryParse(_sponsorAmountCtl.text.trim()) ?? 0.0,
                startDate: _sponsorStart ?? DateTime.now(),
                relationship: _relationshipCtl.text.trim(),
              ),
    );
    await _storage.saveChild(child);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Child saved')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Child')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 4)
              setState(() => _currentStep++);
            else
              _submit();
          },
          onStepCancel: () {
            if (_currentStep > 0)
              setState(() => _currentStep--);
            else
              Navigator.of(context).pop();
          },
          steps: [
            Step(
              title: const Text('Basic Information'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _fullNameCtl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _childIdCtl,
                    decoration: const InputDecoration(
                      labelText: "Child's ID Number",
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dob == null
                              ? 'Date of birth not set'
                              : 'DOB: ${_dob!.toLocal().toIso8601String().split('T').first}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2015),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _dob = d);
                        },
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _fatherNameCtl,
                    decoration: const InputDecoration(
                      labelText: "Father's Name",
                    ),
                  ),
                  TextFormField(
                    controller: _fatherIdCtl,
                    decoration: const InputDecoration(
                      labelText: "Father's ID Number",
                    ),
                  ),
                  TextFormField(
                    controller: _motherNameCtl,
                    decoration: const InputDecoration(
                      labelText: "Mother's Name",
                    ),
                  ),
                  TextFormField(
                    controller: _motherIdCtl,
                    decoration: const InputDecoration(
                      labelText: "Mother's ID Number",
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _motherStatus,
                    items: const [
                      DropdownMenuItem(value: 'Alive', child: Text('Alive')),
                      DropdownMenuItem(
                        value: 'Deceased',
                        child: Text('Deceased'),
                      ),
                    ],
                    onChanged:
                        (v) => setState(() => _motherStatus = v ?? 'Alive'),
                    decoration: const InputDecoration(
                      labelText: "Mother's Status",
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Health & Family'),
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _healthStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'Healthy',
                        child: Text('Healthy'),
                      ),
                      DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                      DropdownMenuItem(
                        value: 'Disabled',
                        child: Text('Disabled'),
                      ),
                    ],
                    onChanged:
                        (v) => setState(() => _healthStatus = v ?? 'Healthy'),
                    decoration: const InputDecoration(
                      labelText: 'Health Status',
                    ),
                  ),
                  TextFormField(
                    controller: _disabilityCtl,
                    decoration: const InputDecoration(
                      labelText:
                          'Type of Disability / Chronic Disease (if any)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final nameCtl = TextEditingController();
                      final idCtl = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Add sibling'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameCtl,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                  ),
                                  TextField(
                                    controller: idCtl,
                                    decoration: const InputDecoration(
                                      labelText: 'ID Number',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                      );
                      if (ok == true)
                        setState(
                          () => _siblings.add({
                            'name': nameCtl.text.trim(),
                            'id': idCtl.text.trim(),
                          }),
                        );
                    },
                    child: const Text('Add Sibling'),
                  ),
                  for (final s in _siblings)
                    ListTile(
                      title: Text(s['name'] ?? ''),
                      subtitle: Text('ID: ${s['id'] ?? ''}'),
                    ),
                ],
              ),
            ),
            Step(
              title: const Text('Documents'),
              content: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickFile('photo'),
                    child: const Text('Upload Child Photo'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickFile('birth_certificate'),
                    child: const Text('Upload Birth Certificate'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickFile('father_id'),
                    child: const Text("Upload Father's ID"),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickFile('father_death_certificate'),
                    child: const Text("Upload Father's Death Certificate"),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickFile('medical'),
                    child: const Text('Upload Medical/Disability Report'),
                  ),
                  const SizedBox(height: 8),
                  for (final d in _documents)
                    ListTile(title: Text(d.fileName), subtitle: Text(d.type)),
                ],
              ),
            ),
            Step(
              title: const Text('Sponsorship'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _sponsorNameCtl,
                    decoration: const InputDecoration(
                      labelText: "Sponsor's Name",
                    ),
                  ),
                  TextFormField(
                    controller: _sponsorAmountCtl,
                    decoration: const InputDecoration(
                      labelText: 'Sponsorship Amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sponsorStart == null
                              ? 'Sponsor start date not set'
                              : 'Start: ${_sponsorStart!.toLocal().toIso8601String().split('T').first}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setState(() => _sponsorStart = d);
                        },
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _relationshipCtl,
                    decoration: const InputDecoration(
                      labelText: 'Relationship between Sponsor and Child',
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Finish'),
              content: Column(children: [const Text('Review & Submit')]),
            ),
          ],
        ),
      ),
    );
  }
}
