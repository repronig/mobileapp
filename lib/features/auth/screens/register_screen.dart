import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/terms_html_dialog.dart';
import '../../../widgets/member_auth_layout.dart';
import '../../../widgets/member_form_fields.dart';
import '../../../widgets/member_tactile_press.dart';
import '../models/public_association.dart';
import '../providers/auth_session_provider.dart';
import 'confirm_otp_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routePath = '/register';
  static const routeName = 'register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  List<PublicAssociation> _associations = [];
  int? _associationId;
  String _applicantType = 'author';
  var _acceptedTerms = false;
  late final TapGestureRecognizer _termsTap;
  var _loading = false;
  var _loadingAssociations = true;
  var _obscurePassword = true;
  var _obscurePasswordConfirmation = true;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTermsModal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLookups());
  }

  Future<void> _loadLookups() async {
    setState(() => _loadingAssociations = true);
    final api = ref.read(authApiProvider);

    try {
      final associations = await api.listAssociations(perPage: 100);
      if (!mounted) return;
      setState(() {
        _associations = associations;
        _loadingAssociations = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _associations = [];
        _loadingAssociations = false;
      });
      MemberFeedback.showError(context, e);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _associations = [];
        _loadingAssociations = false;
      });
      MemberFeedback.showInfo(context, 'Could not load associations.');
    }
  }

  Future<void> _openTermsModal() async {
    try {
      final data = await ref
          .read(authApiProvider)
          .activeTerms(audience: 'member');
      if (!mounted) return;
      final title =
          data?['title'] as String? ?? 'REPRONIG Terms and Conditions';
      final version = data?['version'] as String?;
      final content =
          data?['content'] as String? ??
          'Terms and conditions have not been published yet. Please contact REPRONIG support.';
      await showTermsHtmlDialog(
        context,
        title: title,
        version: version,
        body: content,
      );
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      MemberFeedback.showInfo(
        context,
        'You must agree to the terms and conditions.',
      );
      return;
    }
    if (_associationId == null) {
      MemberFeedback.showInfo(context, 'Select an association.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authApiProvider).registerMember(<String, dynamic>{
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'password_confirmation': _passwordConfirmation.text,
        'applicant_type': _applicantType,
        'association_id': _associationId,
        'accepted_terms': true,
      });
      if (mounted) {
        MemberFeedback.showSuccess(
          context,
          'Check your email for the verification code.',
        );
        context.push(ConfirmOtpScreen.routePath, extra: _email.text.trim());
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
      actions: [
        if (!_loadingAssociations)
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadLookups,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Your \nMembership Account',
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
              'Complete the form below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const MemberFormFieldLabel(text: 'First name', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: memberFormInputDecoration(theme),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'First name is required.'
                  : null,
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Last name', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: memberFormInputDecoration(theme),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Last name is required.'
                  : null,
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Email', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: memberFormInputDecoration(
                theme,
                hint: 'you@example.com',
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required.';
                if (!s.contains('@')) return 'Enter a valid email address.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Phone', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: memberFormInputDecoration(theme),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone is required.' : null,
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Applicant type', required: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _applicantType,
              isExpanded: true,
              decoration: memberFormInputDecoration(theme, hint: 'Select type'),
              dropdownColor: theme.colorScheme.surface,
              iconEnabledColor: theme.colorScheme.onSurfaceVariant,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              items: const [
                DropdownMenuItem(value: 'author', child: Text('Author')),
                DropdownMenuItem(value: 'publisher', child: Text('Publisher')),
              ],
              onChanged: (v) => setState(() => _applicantType = v ?? 'author'),
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Association', required: true),
            const SizedBox(height: 8),
            if (_loadingAssociations)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_associations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No societies are listed for registration.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _associationId,
                isExpanded: true,
                menuMaxHeight: (MediaQuery.sizeOf(context).height * 0.45).clamp(
                  200.0,
                  420.0,
                ),
                decoration: memberFormInputDecoration(
                  theme,
                  hint: 'Select Association',
                ),
                dropdownColor: theme.colorScheme.surface,
                iconEnabledColor: theme.colorScheme.onSurfaceVariant,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                items: _associations
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _associationId = v),
                validator: (v) => v == null ? 'Select an association.' : null,
              ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(text: 'Password', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: memberFormInputDecoration(
                theme,
                hint: 'At least 8 characters',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) {
                final s = v ?? '';
                if (s.length < 8) return 'At least 8 characters.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const MemberFormFieldLabel(
              text: 'Confirm password',
              required: true,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordConfirmation,
              obscureText: _obscurePasswordConfirmation,
              decoration: memberFormInputDecoration(
                theme,
                suffixIcon: IconButton(
                  tooltip: _obscurePasswordConfirmation
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: () => setState(
                    () => _obscurePasswordConfirmation =
                        !_obscurePasswordConfirmation,
                  ),
                  icon: Icon(
                    _obscurePasswordConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              validator: (v) {
                if (v != _password.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) =>
                            setState(() => _acceptedTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the REPRONIG '),
                            TextSpan(
                              text: 'terms and conditions',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsTap,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            MemberTactilePress(
              enabled: !(_loading || _loadingAssociations),
              child: FilledButton(
                onPressed: (_loading || _loadingAssociations) ? null : _submit,
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
                        'Create account',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.go(LoginScreen.routePath),
                child: Text(
                  'Already have an account? Sign in',
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
