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
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  static const routePath = '/reset-password';
  static const routeName = 'reset-password';

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  var _loading = false;
  var _verifyScheduled = false;
  var _obscurePassword = true;
  var _obscurePasswordConfirm = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _token = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final qEmail = uri.queryParameters['email'];
    final qToken = uri.queryParameters['token'];
    if (qEmail != null && _email.text.isEmpty) _email.text = qEmail;
    if (qToken != null && _token.text.isEmpty) _token.text = qToken;
    if (qEmail != null && qToken != null && !_verifyScheduled) {
      _verifyScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyToken());
    }
  }

  Future<void> _verifyToken() async {
    final email = _email.text.trim();
    final token = _token.text.trim();
    if (email.isEmpty || token.isEmpty) return;
    try {
      await ref
          .read(authApiProvider)
          .verifyResetToken(email: email, token: token);
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authApiProvider)
          .resetPassword(
            email: _email.text.trim(),
            token: _token.text.trim(),
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
          );
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Password updated. You can sign in now.');
        context.go(LoginScreen.routePath);
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberAuthLayout(
      title: 'Reset password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set a new secure password for your member account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const MemberFormFieldLabel(text: 'Email', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: memberFormInputDecoration(theme, hint: 'you@example.com'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Email is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            const MemberFormFieldLabel(text: 'Reset token', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _token,
              decoration: memberFormInputDecoration(theme, hint: 'Enter token'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Token is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            const MemberFormFieldLabel(text: 'New password', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: memberFormInputDecoration(
                theme,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                final s = v ?? '';
                if (s.length < 8) return 'At least 8 characters.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const MemberFormFieldLabel(text: 'Confirm password', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordConfirmation,
              obscureText: _obscurePasswordConfirm,
              decoration: memberFormInputDecoration(
                theme,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                  icon: Icon(_obscurePasswordConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                if (v != _password.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            MemberTactilePress(
              enabled: !_loading,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                      )
                    : Text(
                        'Reset password',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
