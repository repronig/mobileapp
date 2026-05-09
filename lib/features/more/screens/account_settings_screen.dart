import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../../widgets/member_form_fields.dart';
import '../providers/more_providers.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = 'member-more-settings';

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  var _deletionFlowBusy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(moreApiProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
            newPasswordConfirmation: _confirm.text,
          );
      if (mounted) {
        _current.clear();
        _next.clear();
        _confirm.clear();
        MemberFeedback.showSuccess(context, 'Password updated.');
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Request account deletion'),
          content: Text(
            'Your account will be '
            'deleted within two weeks. You may contact our support team if done by mistake.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;

    setState(() => _deletionFlowBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _deletionFlowBusy = false);
    MemberFeedback.showInfo(
      context,
      'Account deletion request is now in progress. '
      'Please contact REPRONIG support from the help channels if further support is required.',
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.42,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MemberFormFieldLabel(text: label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: true,
            decoration: memberFormInputDecoration(theme),
            validator: validator,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const MemberBrandAppBar(
        title: 'Account settings',
        showAvatar: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Security',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Update your password. You will stay signed in on this device.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(
                      theme,
                      icon: Icons.lock_outline_rounded,
                      title: 'Change password',
                      subtitle:
                          'Use at least 8 characters for your new password.',
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      theme: theme,
                      controller: _current,
                      label: 'Current password',
                      validator: (s) =>
                          (s == null || s.isEmpty) ? 'Required.' : null,
                    ),
                    _passwordField(
                      theme: theme,
                      controller: _next,
                      label: 'New password',
                      validator: (s) {
                        if (s == null || s.length < 8) {
                          return 'At least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    _passwordField(
                      theme: theme,
                      controller: _confirm,
                      label: 'Confirm new password',
                      validator: (s) {
                        if (s != _next.text) {
                          return 'Does not match new password.';
                        }
                        return null;
                      },
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Update password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader(
                    theme,
                    icon: Icons.delete_forever_outlined,
                    title: 'Request account deletion',
                    subtitle:
                        'Submit a deletion request. Note: once your account is deleted, all data cannot be recovered.',
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFFFF4EC)
                          : theme.colorScheme.errorContainer.withValues(
                              alpha: 0.20,
                            ),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFF3D3C2)
                            : theme.colorScheme.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Deletion requests are reviewed by REPRONIG Admin before processing.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.42,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _deletionFlowBusy
                        ? null
                        : _requestAccountDeletion,
                    icon: _deletionFlowBusy
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.report_gmailerrorred_rounded),
                    label: Text(
                      _deletionFlowBusy
                          ? 'Preparing request…'
                          : 'Request account deletion',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
