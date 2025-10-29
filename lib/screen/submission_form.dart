import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionForm extends StatefulWidget {
  final String challengeId;
  const SubmissionForm({super.key, required this.challengeId});

  @override
  State<SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends State<SubmissionForm>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutQuart),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 🖼️ Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        final fileSize = await file.length();

        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          _showErrorSnackbar(
            'Image is too large. Please select an image under 10MB.',
          );
          return;
        }

        setState(() => _selectedImage = file);
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      if (mounted) {
        _showErrorSnackbar('Failed to pick image: ${e.toString()}');
      }
    }
  }

  // 🚀 Upload to Supabase + insert record
  Future<void> _submit() async {
    if (!_validateForm()) return;

    final supabase = Supabase.instance.client;
    String? imageUrl;

    try {
      setState(() => _isLoading = true);

      // 🖼️ Upload image if exists
      if (_selectedImage != null) {
        debugPrint('Uploading ${_selectedImage!.path}');
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';

        // Upload with proper error handling
        final uploadResponse = await supabase.storage
            .from('submissions')
            .upload(fileName, _selectedImage!);

        if (uploadResponse.isNotEmpty) {
          imageUrl = supabase.storage
              .from('submissions')
              .getPublicUrl(fileName);
          debugPrint('✅ Uploaded to: $imageUrl');
        } else {
          throw Exception('Failed to upload image');
        }
      }

      // 🗃️ Insert record into "submissions" table
      final response = await supabase.from('submissions').insert({
        'challenge_id': widget.challengeId,
        'text_response': _textController.text.trim(),
        'media_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty && mounted) {
        _showSuccessSnackbar('✨ Submission created successfully!');
        _resetForm();
      } else {
        throw Exception('Failed to create submission');
      }
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error: ${e.message}');
      if (mounted) {
        _showErrorSnackbar('Database error: ${e.message}');
      }
    } on StorageException catch (e) {
      debugPrint('❌ Storage error: ${e.message}');
      if (mounted) {
        _showErrorSnackbar('Storage error: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      if (mounted) {
        _showErrorSnackbar('Upload failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Validate form before submission
  bool _validateForm() {
    if (_textController.text.trim().isEmpty && _selectedImage == null) {
      _showErrorSnackbar('Please add some content before submitting');
      return false;
    }

    if (_textController.text.trim().length > 1000) {
      _showErrorSnackbar('Text response is too long (max 1000 characters)');
      return false;
    }

    return true;
  }

  // 🔄 Reset form after successful submission
  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _textController.clear();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Icon(Icons.auto_awesome_rounded, color: Colors.amber);
              },
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Futuristic App Bar
              SliverAppBar(
                backgroundColor: const Color(0xFF1A1A2E),
                elevation: 0,
                pinned: true,
                title: Text(
                  'Create Submission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Form Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Text Input Section
                      _buildTextInputSection(),
                      const SizedBox(height: 32),

                      // Media Section
                      _buildMediaSection(),
                      const SizedBox(height: 40),

                      // Submit Button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Transform.scale(
                scale: _glowAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.8),
                        Colors.blue.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Creation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Express your creativity with text and media',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Response',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_textController.text.length}/1000',
              style: TextStyle(
                color: _textController.text.length > 1000
                    ? Colors.red.withOpacity(0.8)
                    : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _textController.text.length > 1000
                  ? Colors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: _textController,
            maxLines: 6,
            maxLength: 1000,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Share your creative thoughts, story, or response...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              counterText: '', // Hide default counter
            ),
            onChanged: (value) {
              setState(() {}); // Rebuild to update character count
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Attachment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),

        // Image Preview
        if (_selectedImage != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),

                  // Overlay with remove button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Media Actions
        Row(
          children: [
            Expanded(
              child: _buildMediaActionButton(
                icon: Icons.photo_library_rounded,
                text: _selectedImage != null ? 'Change Image' : 'Add Image',
                onPressed: _pickImage,
                color: Colors.blue,
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildMediaActionButton(
                  icon: Icons.delete_rounded,
                  text: 'Remove',
                  onPressed: () => setState(() => _selectedImage = null),
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),

        // No Media State
        if (_selectedImage == null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Image Selected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a photo to enhance your submission',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasContent =
        _textController.text.trim().isNotEmpty || _selectedImage != null;
    final canSubmit =
        hasContent && !_isLoading && _textController.text.length <= 1000;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: canSubmit
            ? LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.8),
                  Colors.blue.withOpacity(0.8),
                ],
              )
            : null,
        color: !canSubmit ? Colors.white.withOpacity(0.2) : null,
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? _submit : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: canSubmit ? _glowAnimation.value : 1.0,
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 12),
                Text(
                  _isLoading
                      ? 'Creating...'
                      : canSubmit
                      ? 'Publish Creation'
                      : hasContent && _textController.text.length > 1000
                      ? 'Text too long'
                      : 'Add Content to Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
