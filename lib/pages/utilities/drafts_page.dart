import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/child.dart';
import '../../services/storage_service.dart';
import '../registration/registration_form.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  final _storage = StorageService();
  List<File> _draftFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    try {
      final baseDir = await _storage.getBaseDir();
      final draftsDir = Directory('${baseDir.path}/drafts');
      if (await draftsDir.exists()) {
        final files =
            draftsDir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'))
                .toList();
        files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
        setState(() => _draftFiles = files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to load drafts: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Child?> _loadDraftChild(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Child.fromJson(json);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to parse draft: $e'),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _deleteDraft(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Draft'),
            content: const Text('Are you sure you want to delete this draft?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await file.delete();
        await _loadDrafts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.blue,
              content: Text('Draft deleted'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Failed to delete draft: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _openDraft(File file) async {
    final child = await _loadDraftChild(file);
    if (child != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => RegistrationForm(child: child)),
      );
      // Reload drafts after returning from registration form
      _loadDrafts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Registrations'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrafts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _draftFiles.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No draft registrations',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _draftFiles.length,
                itemBuilder: (context, index) {
                  final file = _draftFiles[index];
                  final fileName = file.path.split('/').last;
                  final stat = file.statSync();
                  final modified = stat.modified;
                  final dateStr =
                      '${modified.day}/${modified.month}/${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Modified: $dateStr'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await _deleteDraft(file);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                      onTap: () => _openDraft(file),
                    ),
                  );
                },
              ),
    );
  }
}
