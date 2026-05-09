import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_auth_layout.dart';
import '../../../widgets/member_form_fields.dart';
import '../../../widgets/member_tactile_press.dart';
import '../providers/auth_session_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'two_factor_screen.dart';
import '../../shell/member_paths.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';
  static const routeName = 'login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .loginWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      final auth = ref.read(authSessionProvider);
      if (auth.pendingTwoFactor != null && mounted) {
        context.go(TwoFactorScreen.routePath);
        return;
      }
      if (mounted) {
        context.go(
          MemberPaths.afterAuth(
            emailVerified: auth.user!.emailVerified,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } catch (e) {
      if (mounted) {
        MemberFeedback.showError(
          context,
          e,
          fallback: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MemberAuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in with your REPRONIG member account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            const MemberFormFieldLabel(text: 'Email', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: memberFormInputDecoration(theme, hint: 'you@example.com'),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required.';
                if (!s.contains('@')) return 'Enter a valid email address.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Password', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: memberFormInputDecoration(
                theme,
                suffixIcon: IconButton(
                  tooltip:
                      _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required.' : null,
            ),
            const SizedBox(height: 28),
            MemberTactilePress(
              enabled: !_loading,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Sign in',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.push(ForgotPasswordScreen.routePath),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.push(RegisterScreen.routePath),
                child: Text(
                  'Create member account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
