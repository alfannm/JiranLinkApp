import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  int _slideDirection = 1;

  // Login form
  final _loginKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginObscure = true;

  // Register form
  final _registerKey = GlobalKey<FormState>();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();

    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  void _switchTab(bool toLogin) {
    if (_isLogin == toLogin) return;
    setState(() {
      _slideDirection = toLogin ? -1 : 1;
      _isLogin = toLogin;
    });
  }

  Future<void> _handleGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLoginEmail(BuildContext context) async {
    final valid = _loginKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      await auth.signInWithEmail(
        _loginEmail.text.trim(),
        _loginPassword.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegisterEmail(BuildContext context) async {
    final valid = _registerKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      await auth.registerWithEmail(
        _regName.text.trim(),
        _regEmail.text.trim(),
        _regPassword.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              size: 260,
              color: AppTheme.primary.withOpacity(0.18),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _GlowBlob(
              size: 280,
              color: AppTheme.primaryDark.withOpacity(0.18),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.32),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'JiranLink',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.foreground,
                          ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Share resources, build community',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 42),

                    // Auth Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSegmentedToggle(),
                          const SizedBox(height: 24),

                          ClipRect(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 360),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, anim) {
                                  final isIncoming = child.key ==
                                      ValueKey(_isLogin ? 'login' : 'register');
                                  final offset = Offset(-0.18 * _slideDirection, 0);
                                  final slideTween = Tween<Offset>(
                                    begin: isIncoming ? offset : Offset.zero,
                                    end: isIncoming ? Offset.zero : offset,
                                  );
                                  final slideAnim = anim;
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: slideTween.animate(slideAnim),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _AuthContent(
                                  key: ValueKey(_isLogin ? 'login' : 'register'),
                                  isLogin: _isLogin,
                                  loginForm: _loginForm(context),
                                  registerForm: _registerForm(context),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Divider(color: AppTheme.border),
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleGoogle(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.foreground,
                                elevation: 0,
                                side: const BorderSide(color: AppTheme.border),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://www.google.com/favicon.ico',
                                              width: 24,
                                              height: 24,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(Icons.g_mobiledata,
                                                    size: 24);
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Continue with Google',
                                              style: TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            'By continuing, you agree to our Terms of Service and Privacy Policy',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return Form(
      key: _loginKey,
      child: Column(
        children: [
          _textField(
            controller: _loginEmail,
            label: 'Email',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Email is required';
              if (!s.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _loginPassword,
            label: 'Password',
            hint: 'At least 6 characters',
            obscureText: _loginObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
              icon: Icon(_loginObscure ? Icons.visibility : Icons.visibility_off),
            ),
            textInputAction: TextInputAction.done,
            validator: (v) {
              final s = (v ?? '');
              if (s.isEmpty) return 'Password is required';
              if (s.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLoginEmail(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerForm(BuildContext context) {
    return Form(
      key: _registerKey,
      child: Column(
        children: [
          _textField(
            controller: _regName,
            label: 'Full Name',
            hint: 'e.g., Ali bin Abu',
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Name is required';
              if (s.length < 2) return 'Name is too short';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _regEmail,
            label: 'Email',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Email is required';
              if (!s.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _regPassword,
            label: 'Password',
            hint: 'At least 6 characters',
            obscureText: _regObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _regObscure = !_regObscure),
              icon: Icon(_regObscure ? Icons.visibility : Icons.visibility_off),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '');
              if (s.isEmpty) return 'Password is required';
              if (s.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _regConfirm,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            obscureText: _regConfirmObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
              icon: Icon(_regConfirmObscure ? Icons.visibility : Icons.visibility_off),
            ),
            textInputAction: TextInputAction.done,
            validator: (v) {
              final s = (v ?? '');
              if (s.isEmpty) return 'Confirm your password';
              if (s != _regPassword.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleRegisterEmail(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.secondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.8), width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 4.0;
        final segmentWidth = (constraints.maxWidth - (padding * 2)) / 2;

        return Container(
          height: 48,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: _isLogin ? 0 : segmentWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: segmentWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Login',
                      _isLogin,
                      () => _switchTab(true),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      'Register',
                      !_isLogin,
                      () => _switchTab(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({
    super.key,
    required this.isLogin,
    required this.loginForm,
    required this.registerForm,
  });

  final bool isLogin;
  final Widget loginForm;
  final Widget registerForm;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(isLogin ? 'loginContent' : 'registerContent'),
      children: [
        Text(
          isLogin ? 'Welcome Back' : 'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.foreground,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Sign in to continue sharing and borrowing'
              : 'Join JiranLink and start building community connections',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        isLogin ? loginForm : registerForm,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
