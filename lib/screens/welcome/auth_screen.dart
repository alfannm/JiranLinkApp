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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 48),

                // Auth Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Toggle Login/Register (retain style)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
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
                      ),
                      const SizedBox(height: 26),

                      // Header
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Column(
                          key: ValueKey(_isLogin ? 'loginHeader' : 'registerHeader'),
                          children: [
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.foreground,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? 'Sign in to continue sharing and borrowing'
                                  : 'Join JiranLink and start building community connections',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Static forms (no expand/collapse)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isLogin
                            ? Container(
                                key: const ValueKey('loginForm'),
                                child: _loginForm(context),
                              )
                            : Container(
                                key: const ValueKey('registerForm'),
                                child: _registerForm(context),
                              ),
                      ),

                      const SizedBox(height: 18),

                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 14),

                      // Google button under divider
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.g_mobiledata, size: 24);
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

                      // Terms
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
            hint: '••••••••',
            obscureText: _loginObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
              icon: Icon(_loginObscure ? Icons.visibility : Icons.visibility_off),
            ),
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
            hint: '••••••••',
            obscureText: _regObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _regObscure = !_regObscure),
              icon: Icon(_regObscure ? Icons.visibility : Icons.visibility_off),
            ),
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
            hint: '••••••••',
            obscureText: _regConfirmObscure,
            suffix: IconButton(
              onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
              icon: Icon(_regConfirmObscure ? Icons.visibility : Icons.visibility_off),
            ),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
