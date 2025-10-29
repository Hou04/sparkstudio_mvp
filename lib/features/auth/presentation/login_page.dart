/// 🔐 Futuristic Login Page
/// 
/// Professional login interface with glass morphism effects,
/// smooth animations, and excellent user experience.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/utils/logger.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/widgets/custom_input.dart';
import '../logic/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _handleAuthentication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authController = context.read<AuthController>();

    try {
      if (_isSignUp) {
        await authController.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      } else {
        await authController.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      Logger.error('❌ Authentication failed: $e', tag: 'LoginPage');
      // Error is handled by the auth controller and shown in UI
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address first'),
          backgroundColor: AppColors.warning.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    
    try {
      await authController.resetPassword(_emailController.text.trim());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent! Check your inbox.'),
          backgroundColor: AppColors.info.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ Password reset failed: $e', tag: 'LoginPage');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: _slideAnimation.value,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // Header Section
                        _buildHeaderSection(),
                        const SizedBox(height: 48),
                        
                        // Auth Form
                        _buildAuthForm(),
                        const SizedBox(height: 32),
                        
                        // Footer Section
                        _buildFooterSection(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Animated Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 45,
          ),
        ),
        const SizedBox(height: 24),
        
        // Title
        Text(
          AppTexts.appName,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          _isSignUp ? 'Join the Creative Revolution' : 'Unleash Your Creativity',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Auth Mode Toggle
            _buildAuthModeToggle(),
            const SizedBox(height: AppSizes.spaceXL),
            
            // Name Field (Sign Up Only)
            if (_isSignUp) ...[
              CustomInput(
                controller: _nameController,
                hint: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(height: AppSizes.spaceM),
            ],
            
            // Email Field
            CustomInput(
              controller: _emailController,
              hint: AppTexts.email,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSizes.spaceM),
            
            // Password Field
            CustomInput(
              controller: _passwordController,
              hint: AppTexts.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              obscureText: true,
            ),
            const SizedBox(height: AppSizes.spaceL),
            
            // Forgot Password (Login Only)
            if (!_isSignUp) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text(
                    AppTexts.forgotPassword,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
            ],
            
            // Submit Button
            Consumer<AuthController>(
              builder: (context, authController, child) {
                return CustomButton(
                  label: _isSignUp ? AppTexts.signUp : AppTexts.signIn,
                  onPressed: _isLoading ? null : _handleAuthentication,
                  isLoading: _isLoading || authController.isLoading,
                  gradient: AppColors.primaryGradient,
                  height: AppSizes.buttonHeight,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: !_isSignUp ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                color: _isSignUp ? Colors.transparent : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !_isSignUp ? null : _toggleAuthMode,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spaceM,
                      horizontal: AppSizes.spaceM,
                    ),
                    child: Text(
                      AppTexts.signIn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isSignUp ? Colors.white : Colors.white70,
                        fontWeight: !_isSignUp ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: _isSignUp ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                color: !_isSignUp ? Colors.transparent : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSignUp ? null : _toggleAuthMode,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spaceM,
                      horizontal: AppSizes.spaceM,
                    ),
                    child: Text(
                      AppTexts.signUp,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isSignUp ? Colors.white : Colors.white70,
                        fontWeight: _isSignUp ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withOpacity(0.3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceL),
        
        // Social Login Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(Icons.g_mobiledata, 'Google'),
            const SizedBox(width: AppSizes.spaceM),
            _buildSocialButton(Icons.apple, 'Apple'),
            const SizedBox(width: AppSizes.spaceM),
            _buildSocialButton(Icons.facebook, 'Facebook'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Handle social login
              Logger.info('$label login tapped', tag: 'LoginPage');
            },
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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