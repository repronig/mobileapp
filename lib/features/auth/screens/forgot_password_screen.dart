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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routePath = '/forgot-password';
  static const routeName = 'forgot-password';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authApiProvider).forgotPassword(email: _email.text.trim());
      if (mounted) {
        MemberFeedback.showSuccess(
          context,
          'If an account exists, a reset link has been sent.',
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(LoginScreen.routePath);
        }
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
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
              'Enter the email for your member account. If it matches an account, we will send reset instructions.',
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
              decoration: memberFormInputDecoration(theme, hint: 'you@example.com'),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required.';
                if (!s.contains('@')) return 'Enter a valid email address.';
                return null;
              },
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
                        'Send reset link',
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
                    : () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(LoginScreen.routePath);
                        }
                      },
                child: Text(
                  'Back to sign in',
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
