import 'dart:io';
import 'package:flutter/material.dart';

// Fallback minimal image_picker types if the external package isn't available.
enum ImageSource { gallery, camera }

class XFile {
  final String path;
  XFile(this.path);
}

class ImagePicker {
  Future<XFile?> pickImage({required ImageSource source}) async {
    return null;
  }
}

class SubmissionController {
  Future<void> submit({
    required String challengeId,
    required String textResponse,
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return;
  }
}

class NewSubmissionScreen extends StatefulWidget {
  final String challengeId;
  const NewSubmissionScreen({super.key, required this.challengeId});

  @override
  State<NewSubmissionScreen> createState() => _NewSubmissionScreenState();
}

class _NewSubmissionScreenState extends State<NewSubmissionScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;
  final _controller = SubmissionController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _controller.submit(
        challengeId: widget.challengeId,
        textResponse: _textCtrl.text.trim(),
        imagePath: _imageFile?.path,
      );
      if (!mounted) return;
      _showSuccessSnackbar('🎉 Submission created successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar('Submission failed: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF1A1A2E),
              elevation: 0,
              pinned: true,
              title: Text(
                'New Submission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (_isSubmitting)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Text Input
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextFormField(
                          controller: _textCtrl,
                          maxLines: 5,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Share your creative response...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) && _imageFile == null
                                  ? 'Enter text or add an image'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Preview
                      if (_imageFile != null)
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              text: 'Add Image',
                              icon: Icons.add_photo_alternate_rounded,
                              onPressed: _isSubmitting ? null : _pickImage,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_imageFile != null)
                            Expanded(
                              child: _buildActionButton(
                                text: 'Remove',
                                icon: Icons.delete_rounded,
                                onPressed: _isSubmitting 
                                    ? null 
                                    : () => setState(() => _imageFile = null),
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: !_isSubmitting
                              ? LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.8),
                                    Colors.blue.withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: _isSubmitting ? Colors.white.withOpacity(0.3) : null,
                          boxShadow: !_isSubmitting
                              ? [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _onSubmit,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSubmitting)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  else
                                    Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isSubmitting ? 'Creating...' : 'Create Submission',
                                    style: const TextStyle(
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: onPressed != null
                  ? color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, 
                color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5), 
                size: 18
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
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
}