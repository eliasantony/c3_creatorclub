import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

/// Combined Auth screen: defaults to Sign Up with switch to Login.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = false; // default to Register per PRD
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await auth.signInWithEmail(_email.text.trim(), _password.text);
        if (!mounted) return;
        context.go('/rooms');
      } else {
        // Create account with minimum required fields
        await auth.registerWithEmail(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim().isEmpty ? 'Creator' : _name.text.trim(),
        );
        
        if (!mounted) return;
        // Send to onboarding
        context.go('/onboarding');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final isLoading = ref.watch(authStateChangesProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black,
              AppColors.primary.withOpacity(isDark ? 0.85 : 1.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.white.withAlpha(75),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/logo.svg',
                              width: 120,
                              height: 120,
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'creative - creator - club',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 64),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            _isLogin ? 'Welcome back' : 'Create your account',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _name,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (_isLogin) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              AutofillGroup(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _email,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                      ),
                                      autofillHints: [
                                        AutofillHints.newUsername,
                                        AutofillHints.username,
                                      ],
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                          ? 'Invalid email'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _password,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: [AutofillHints.password],
                                      obscureText: true,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                          ? 'Min 6 characters'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: (isLoading || _loading)
                                      ? null
                                      : _submit,
                                  child: (isLoading || _loading)
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(_isLogin ? 'Log in' : 'Sign up'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin
                                      ? "Don't have an account? Sign up"
                                      : 'Already have an account? Login.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
