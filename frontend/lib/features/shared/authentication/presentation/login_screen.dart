import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanet_mobile/core/theme/theme.dart';
import 'package:vanet_mobile/features/shared/authentication/presentation/auth_provider.dart';

enum AuthViewMode { login, signup, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AuthViewMode _currentMode = AuthViewMode.login;
  String _selectedRole = "Admin"; // "Admin" or "Driver"

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  String? _successMessage;
  String? _localValidationError;

  @override
  void initState() {
    super.initState();
    // Default helpful hint values
    _emailController.text = "admin@vanet.com";
    _passwordController.text = "";
    _nameController.text = "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _successMessage = null;
      _localValidationError = null;
    });

    if (_currentMode == AuthViewMode.forgotPassword) {
      final email = _forgotEmailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _localValidationError = "Please enter a valid email address.");
        return;
      }
      final success = await ref.read(authProvider.notifier).sendPasswordReset(email);
      if (success && mounted) {
        setState(() {
          _successMessage = "Password reset link sent to $email. Please check your inbox.";
        });
      }
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localValidationError = "Please enter a valid email address.");
      return;
    }

    if (password.length < 6) {
      setState(() => _localValidationError = "Password must be at least 6 characters.");
      return;
    }

    if (_currentMode == AuthViewMode.signup) {
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        setState(() => _localValidationError = "Passwords do not match.");
        return;
      }

      final name = _nameController.text.trim();
      final success = await ref.read(authProvider.notifier).signUp(
            email,
            password,
            name: name.isNotEmpty ? name : (_selectedRole == 'Admin' ? 'Admin Operator' : 'Vehicle Driver'),
            role: _selectedRole,
          );

      if (success && mounted) {
        _navigateAfterAuth();
      }
    } else {
      final success = await ref.read(authProvider.notifier).login(
            email,
            password,
            role: _selectedRole,
          );

      if (success && mounted) {
        _navigateAfterAuth();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _successMessage = null;
      _localValidationError = null;
    });

    final success = await ref.read(authProvider.notifier).signInWithGoogle(role: _selectedRole);
    if (success && mounted) {
      _navigateAfterAuth();
    }
  }

  void _navigateAfterAuth() {
    final updatedAuth = ref.read(authProvider);
    if (updatedAuth.isAdmin) {
      context.go('/dashboard');
    } else {
      context.go('/driver/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final displayedError = _localValidationError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentMode != AuthViewMode.login
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _currentMode = AuthViewMode.login;
                    _successMessage = null;
                    _localValidationError = null;
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Badge / Brand Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: AppTheme.primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Titles
                  Text(
                    _getMainTitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getSubtitle(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role Selector Pills
                  if (_currentMode != AuthViewMode.forgotPassword) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleSelector("Admin", Icons.shield_rounded, label: "Admin"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleSelector("Driver", Icons.directions_car_rounded, label: "Driver / Node"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sign Up: Full Name Field
                  if (_currentMode == AuthViewMode.signup) ...[
                    _buildFieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _nameController,
                      hint: 'e.g. John Doe',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  if (_currentMode != AuthViewMode.forgotPassword) ...[
                    _buildFieldLabel('Email Address'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _emailController,
                      hint: _selectedRole == 'Admin' ? 'admin@vanet.com' : 'driver@vanet.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildFieldLabel('Password'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Min. 6 characters',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleObscure: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Sign Up: Confirm Password Field
                    if (_currentMode == AuthViewMode.signup) ...[
                      const SizedBox(height: 4),
                      _buildFieldLabel('Confirm Password'),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: 'Repeat password',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleObscure: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Remember Me & Forgot Password Row (Login mode only)
                    if (_currentMode == AuthViewMode.login)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Text(
                                  'Remember me',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _currentMode = AuthViewMode.forgotPassword;
                                _forgotEmailController.text = _emailController.text;
                                _successMessage = null;
                                _localValidationError = null;
                              });
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],

                  // Forgot Password Mode Input
                  if (_currentMode == AuthViewMode.forgotPassword) ...[
                    _buildFieldLabel('Account Email Address'),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _forgotEmailController,
                      hint: 'Enter your registered email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error Message Banner
                  if (displayedError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayedError,
                              style: GoogleFonts.outfit(
                                color: AppTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Success Message Banner
                  if (_successMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.safe.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.safe.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.safe, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: GoogleFonts.outfit(
                                color: AppTheme.safe,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: authState.isLoading ? null : _handleSubmit,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _getButtonLabel(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                              ),
                            ),
                    ),
                  ),

                  // Google Sign-In (For Login and Signup modes)
                  if (_currentMode != AuthViewMode.forgotPassword) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppTheme.border)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.border, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGoogleIcon(),
                            const SizedBox(width: 12),
                            Text(
                              _currentMode == AuthViewMode.signup ? 'Sign up with Google' : 'Sign in with Google',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Footer Link
                  Center(
                    child: _buildFooterLink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }

  String _getMainTitle() {
    switch (_currentMode) {
      case AuthViewMode.login:
        return 'Welcome Back';
      case AuthViewMode.signup:
        return 'Create Account';
      case AuthViewMode.forgotPassword:
        return 'Reset Password';
    }
  }

  String _getSubtitle() {
    switch (_currentMode) {
      case AuthViewMode.login:
        return 'Sign in with Firebase to access VANET Monitor';
      case AuthViewMode.signup:
        return 'Register new operator node or supervisor';
      case AuthViewMode.forgotPassword:
        return 'Enter your email to receive recovery instructions';
    }
  }

  String _getButtonLabel() {
    switch (_currentMode) {
      case AuthViewMode.login:
        return 'Sign In';
      case AuthViewMode.signup:
        return 'Create Account';
      case AuthViewMode.forgotPassword:
        return 'Send Reset Link';
    }
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildRoleSelector(String role, IconData icon, {String? label}) {
    final isSelected = _selectedRole == role;
    final displayLabel = label ?? role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          if (role == 'Admin') {
            _emailController.text = 'admin@vanet.com';
          } else {
            _emailController.text = 'driver@vanet.com';
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.secondarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              displayLabel,
              style: GoogleFonts.outfit(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 13.5),
          prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    if (_currentMode == AuthViewMode.login) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _currentMode = AuthViewMode.signup;
                _successMessage = null;
                _localValidationError = null;
              });
            },
            child: Text(
              'Sign Up',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else if (_currentMode == AuthViewMode.signup) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _currentMode = AuthViewMode.login;
                _successMessage = null;
                _localValidationError = null;
              });
            },
            child: Text(
              'Login',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else {
      return InkWell(
        onTap: () {
          setState(() {
            _currentMode = AuthViewMode.login;
            _successMessage = null;
            _localValidationError = null;
          });
        },
        child: Text(
          '← Back to Login',
          style: GoogleFonts.outfit(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      );
    }
  }
}
