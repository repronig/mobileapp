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

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  static const routePath = '/two-factor';
  static const routeName = 'two-factor';

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .completeTwoFactor(code: _code.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(authSessionProvider).pendingTwoFactor;

    if (pending == null) {
      return MemberAuthLayout(
        title: 'Two-factor verification',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Your login session is no longer active.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(LoginScreen.routePath),
              child: const Text('Return to sign in'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return MemberAuthLayout(
      title: 'Two-factor verification',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code for ${pending.email}.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Verification code', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: memberFormInputDecoration(theme, hint: '000000').copyWith(counterText: ''),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                  return 'Enter the 6-digit code.';
                }
                return null;
              },
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
                    : const Text('Verify'),
              ),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      ref.read(authSessionProvider.notifier).abandonTwoFactor();
                      context.go(LoginScreen.routePath);
                    },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
