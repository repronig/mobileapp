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
import '../../shell/member_paths.dart';
import 'login_screen.dart';

class ConfirmOtpScreen extends ConsumerStatefulWidget {
  const ConfirmOtpScreen({super.key, required this.initialEmail});

  final String initialEmail;

  static const routePath = '/confirm-otp';
  static const routeName = 'confirm-otp';

  @override
  ConsumerState<ConfirmOtpScreen> createState() => _ConfirmOtpScreenState();
}

class _ConfirmOtpScreenState extends ConsumerState<ConfirmOtpScreen> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  var _loading = false;
  var _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (email.isEmpty || !RegExp(r'^\d{6}$').hasMatch(code)) {
      MemberFeedback.showInfo(context, 'Enter a valid email and 6-digit code.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .completeRegistrationOtp(email: email, code: code);
      if (mounted) {
        final auth = ref.read(authSessionProvider);
        context.go(
          MemberPaths.afterAuth(
            emailVerified: auth.user!.emailVerified,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() => _resendLoading = true);
    try {
      await ref.read(authApiProvider).resendMemberRegistrationOtp(email: email);
      if (mounted) {
        MemberFeedback.showSuccess(context, 'A new code has been sent.');
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberAuthLayout(
      title: 'Verify email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the 6-digit verification code sent to your inbox.',
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
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: memberFormInputDecoration(theme, hint: 'you@example.com'),
          ),
          const SizedBox(height: 16),
          const MemberFormFieldLabel(text: 'OTP code', required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: memberFormInputDecoration(
              theme,
              hint: '000000',
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 20),
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
                      'Verify and continue',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          TextButton(
            onPressed: _resendLoading ? null : _resend,
            child: Text(_resendLoading ? 'Sending…' : 'Resend code'),
          ),
          TextButton(
            onPressed: () => context.go(LoginScreen.routePath),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
