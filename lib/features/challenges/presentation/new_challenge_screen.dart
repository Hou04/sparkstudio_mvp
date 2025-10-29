/// 🆕 Futuristic New Challenge Screen
///
/// Professional challenge creation interface for admins with rich form
/// validation, AI style selection, and preview capabilities.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/widgets/custom_input.dart';
import '../data/challenge_model.dart';

class NewChallengeScreen extends StatefulWidget {
  const NewChallengeScreen({super.key});

  @override
  State<NewChallengeScreen> createState() => _NewChallengeScreenState();
}

class _NewChallengeScreenState extends State<NewChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exampleController = TextEditingController();
  final _coverImageController = TextEditingController();

  ChallengeType _selectedType = ChallengeType.text;
  String _selectedAiStyle = 'creative';
  int _selectedDifficulty = 3;
  int _durationDays = 1;

  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  bool _isLoading = false;
  bool _showPreview = false;

  final List<String> _aiStyles = [
    'creative',
    'fantasy',
    'scifi',
    'romance',
    'comedy',
    'mystery',
    'haiku',
    'story',
    'poem',
    'caption',
    'cinematic',
    'anime',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Create challenge object
      final challenge = ChallengeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        aiStyle: _selectedAiStyle,
        tags: _tags,
        difficulty: _selectedDifficulty,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: _durationDays)),
        exampleContent: _exampleController.text.trim().isNotEmpty
            ? _exampleController.text.trim()
            : null,
        coverImageUrl: _coverImageController.text.trim().isNotEmpty
            ? _coverImageController.text.trim()
            : null,
      );

      // TODO: Save to database
      print('Challenge created: ${challenge.toJson()}');

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Challenge created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _exampleController.dispose();
    _coverImageController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: _slideAnimation.value,
                  child: _showPreview ? _buildPreview() : _buildForm(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Basic Information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Challenge Type
            _buildTypeSection(),
            const SizedBox(height: 24),

            // AI Style
            _buildAiStyleSection(),
            const SizedBox(height: 24),

            // Difficulty & Duration
            _buildSettingsSection(),
            const SizedBox(height: 24),

            // Tags
            _buildTagsSection(),
            const SizedBox(height: 24),

            // Example Content
            _buildExampleSection(),
            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Challenge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Design an inspiring creative prompt',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _titleController,
            hint: 'Challenge Title',
            prefixIcon: const Icon(Icons.title_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _descriptionController,
            hint: 'Challenge Description',
            prefixIcon: const Icon(Icons.description_outlined),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _coverImageController,
            hint: 'Cover Image URL (Optional)',
            prefixIcon: const Icon(Icons.image_outlined),
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Challenge Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ChallengeType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedType = type),
                label: Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                backgroundColor: Colors.transparent,
                selectedColor: _getTypeColor(type).withOpacity(0.3),
                side: BorderSide(
                  color: isSelected
                      ? _getTypeColor(type)
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStyleSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Enhancement Style',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiStyles.map((style) {
              final isSelected = _selectedAiStyle == style;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedAiStyle = style),
                label: Text(
                  style.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.transparent,
                selectedColor: Colors.purple.withOpacity(0.3),
                side: BorderSide(
                  color: isSelected
                      ? Colors.purple
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Challenge Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Difficulty
          const Text(
            'Difficulty Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _selectedDifficulty.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) =>
                setState(() => _selectedDifficulty = value.toInt()),
            activeColor: _getDifficultyColor(_selectedDifficulty),
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Beginner',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                _getDifficultyLabel(_selectedDifficulty),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Expert',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Duration
          const Text(
            'Challenge Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _durationDays.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            onChanged: (value) => setState(() => _durationDays = value.toInt()),
            activeColor: AppColors.secondary,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
          Text(
            '$_durationDays day${_durationDays > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: _tagController,
                  hint: 'Add a tag...',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.white.withOpacity(0.1),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Example Content (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show participants what great submissions look like',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _exampleController,
            hint: 'Provide an example submission or inspiration...',
            prefixIcon: const Icon(Icons.lightbulb_outline),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _togglePreview,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_red_eye_outlined, size: 20),
                SizedBox(width: 8),
                Text('Preview'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            label: 'Create Challenge',
            onPressed: _isLoading ? null : _createChallenge,
            isLoading: _isLoading,
            gradient: AppColors.primaryGradient,
            height: AppSizes.buttonHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final challenge = ChallengeModel(
      id: 'preview',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      aiStyle: _selectedAiStyle,
      tags: _tags,
      difficulty: _selectedDifficulty,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: _durationDays)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        children: [
          // Header
          _buildPreviewHeader(),
          const SizedBox(height: 24),

          // Challenge Preview
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceXL),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _getTypeGradient(challenge.type),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Text(
                        challenge.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            challenge.type.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats
                Row(
                  children: [
                    _buildPreviewStat('Difficulty', challenge.difficultyLabel),
                    const SizedBox(width: 16),
                    _buildPreviewStat('Duration', '$_durationDays days'),
                    const SizedBox(width: 16),
                    _buildPreviewStat(
                      'AI Style',
                      _selectedAiStyle.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Tags
                if (challenge.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: challenge.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Example Content
                if (_exampleController.text.trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Example:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _exampleController.text.trim(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Back Button
          CustomButton(
            label: 'Back to Editing',
            onPressed: _togglePreview,
            gradient: AppColors.secondaryGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: IconButton(
            onPressed: _togglePreview,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Challenge Preview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.photo:
        return Colors.pink;
      case ChallengeType.text:
        return Colors.blue;
      case ChallengeType.video:
        return Colors.purple;
      case ChallengeType.audio:
        return Colors.green;
      case ChallengeType.mixed:
        return Colors.orange;
    }
  }

  Gradient _getTypeGradient(ChallengeType type) {
    switch (type) {
      case ChallengeType.photo:
        return const LinearGradient(
          colors: [Color(0xFFEC407A), Color(0xFFAB47BC)],
        );
      case ChallengeType.text:
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF478ED1)],
        );
      case ChallengeType.video:
        return const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
        );
      case ChallengeType.audio:
        return const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF66BB6A)],
        );
      case ChallengeType.mixed:
        return const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFFA726)],
        );
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Expert';
      default:
        return 'Medium';
    }
  }
}
