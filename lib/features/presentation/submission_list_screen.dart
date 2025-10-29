import 'package:flutter/material.dart';
import 'package:sparkstudio_mvp/features/submissions/submission_controller.dart'
    show SubmissionController;
import '../submissions/submission_controller.dart';

class SubmissionListScreen extends StatefulWidget {
  final String challengeId;
  const SubmissionListScreen({super.key, required this.challengeId});

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  final _controller = SubmissionController();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _controller.getSubmissions(
        challengeId: widget.challengeId,
      );
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('No submissions yet'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final sub = _items[i];
        final text = sub['text_response'] as String?;
        final mediaUrl = sub['media_url'] as String?;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: mediaUrl != null
                ? Image.network(
                    mediaUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.text_snippet),
            title: Text(text ?? 'Image submission'),
            subtitle: Text(sub['created_at'] as String? ?? ''),
          ),
        );
      },
    );
  }
}
