import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class DocumentsPage extends StatefulWidget {
  final VoidCallback? onOpenChildCreate;
  const DocumentsPage({super.key, this.onOpenChildCreate});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final StorageService _storage = StorageService();
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final base = await _storage.getBaseDir();
      final filesDir = Directory('${base.path}/files');
      if (!await filesDir.exists()) {
        setState(() => _files = []);
        return;
      }
      final listed = filesDir.listSync().whereType<File>().toList();
      setState(() => _files = listed);
    } catch (e) {
      setState(() => _files = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndSaveFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_files.length} files',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child:
                    _files.isEmpty
                        ? const Center(child: Text('No uploaded files'))
                        : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (context, index) {
                            final f = _files[index];
                            final name =
                                f.path.split(Platform.pathSeparator).last;
                            final isImage =
                                name.toLowerCase().endsWith('.png') ||
                                name.toLowerCase().endsWith('.jpg') ||
                                name.toLowerCase().endsWith('.jpeg') ||
                                name.toLowerCase().endsWith('.gif');
                            final sizeText =
                                f is File ? _formatBytes(f.lengthSync()) : '';
                            return ListTile(
                              leading:
                                  isImage
                                      ? Image.file(
                                        f as File,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(Icons.description),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(sizeText),
                              trailing: SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.preview, size: 20),
                                      onPressed: () => openFile(f.path),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () async {
                                        try {
                                          (f as File).deleteSync();
                                          await _refresh();
                                        } catch (e) {
                                          // ignore
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final p = result.files.single.path;
    if (p == null) return;
    try {
      await _storage.saveFile(File(p), type: 'document');
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    }
  }

  void openFile(String path) {
    final isImage =
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.gif');

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textDir = isArabic ? TextDirection.rtl : TextDirection.ltr;

    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: textDir,
            child: AlertDialog(
              title: Text(path.split(Platform.pathSeparator).last),
              content: isImage ? Image.file(File(path)) : Text('File: $path'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
    );
  }

  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
