// lib/features/feed/presentation/feed_screen.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/submission_repository.dart';
import '../../../data/supabase/submission_service.dart';
import '../../../data/repositories/ai/ai_generation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final SubmissionRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    // TODO: Get these from dependency injection
    _repo = SubmissionRepository(
      submissionService: SubmissionService(client: Supabase.instance.client),
      aiService: AiGenerationService(apiKey: 'dummy'),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.getSubmissions(limit: 50);
      setState(() {
        _items = res.map((submission) => submission.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Feed load error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_items.isEmpty)
      return Scaffold(
        appBar: AppBar(title: const Text('Feed')),
        body: const Center(child: Text('No posts yet')),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _items.length,
          itemBuilder: (c, i) {
            final it = _items[i];
            final text = it['text_response'] as String?;
            final media = it['media_url'] as String?;
            final user = it['user_id'] as String?;
            final created = it['created_at'] as String?;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (text != null && text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(text),
                    ],
                    if (media != null && media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Image.network(media, fit: BoxFit.cover),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      created ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
