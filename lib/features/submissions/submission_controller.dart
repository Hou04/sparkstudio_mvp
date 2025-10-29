import 'package:sparkstudio_mvp/data/repositories/submission_repository.dart';
import 'package:sparkstudio_mvp/data/supabase/submission_service.dart';
import 'package:sparkstudio_mvp/data/repositories/ai/ai_generation_service.dart';
import 'package:sparkstudio_mvp/data/models/creative_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionController {
  final SubmissionRepository _repo;

  /// Creates a SubmissionController.
  ///
  /// If [submissionService] or [aiService] are not provided, sensible defaults
  /// will be created (Supabase client for submissions and an AiGenerationService
  /// with an empty API key for local development). This makes the controller
  /// easier to construct in UI code without manual DI wiring.
  SubmissionController({
    SubmissionService? submissionService,
    AiGenerationService? aiService,
  }) : _repo = SubmissionRepository(
         submissionService:
             submissionService ??
             SubmissionService(client: Supabase.instance.client),
         aiService: aiService ?? AiGenerationService(apiKey: ''),
       );

  // Called when the user submits a challenge response
  Future<void> submit({
    required String challengeId,
    required String userId,
    required String type,
    String? textResponse,
    String? imagePath,
  }) async {
    await _repo.submit(
      challengeId: challengeId,
      userId: userId,
      type: CreativeType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => CreativeType.text,
      ),
      textResponse: textResponse,
      imagePath: imagePath,
    );
  }

  // Previously: Future<List<Map<String, dynamic>>> getSubmissions(String challengeId)
  // New: accepts optional challengeId and limit
  Future<List<Map<String, dynamic>>> getSubmissions({
    String? challengeId,
    int limit = 50,
  }) async {
    final submissions = await _repo.getSubmissions(
      challengeId: challengeId,
      limit: limit,
    );
    return submissions.map((submission) => submission.toJson()).toList();
  }
}
