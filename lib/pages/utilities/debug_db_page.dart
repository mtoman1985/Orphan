import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';

class DebugDbPage extends StatefulWidget {
  const DebugDbPage({super.key});

  @override
  State<DebugDbPage> createState() => _DebugDbPageState();
}

class _DebugDbPageState extends State<DebugDbPage> {
  List<Map<String, Object?>> _childrenInfo = [];
  List<Map<String, Object?>> _documentsInfo = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = SqliteService();
    final c = await s.getTableInfo('children');
    final d = await s.getTableInfo('documents');
    setState(() {
      _childrenInfo = c;
      _documentsInfo = d;
      _loading = false;
    });
  }

  Widget _buildTableInfo(String title, List<Map<String, Object?>> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (rows.isEmpty) const Text('No columns or unable to query.'),
            for (final r in rows)
              ListTile(
                dense: true,
                title: Text('${r['name'] ?? ''}  (${r['type'] ?? ''})'),
                subtitle: Text(
                  'notnull=${r['notnull'] ?? ''} pk=${r['pk'] ?? ''}',
                ),
                trailing: Text('${r['dflt_value'] ?? ''}'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB Schema (debug)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildTableInfo('children', _childrenInfo),
                    const SizedBox(height: 12),
                    _buildTableInfo('documents', _documentsInfo),
                  ],
                ),
              ),
    );
  }
}
