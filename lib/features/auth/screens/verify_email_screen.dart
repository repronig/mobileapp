import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/theme.dart';
import '../../../widgets/confirm_logout_dialog.dart';
import '../../../widgets/member_auth_layout.dart';
import '../../../widgets/member_surface_card.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../core/providers/secure_token_store_provider.dart';
import '../../shell/member_paths.dart';
import '../models/email_verification_status.dart';
import '../providers/auth_session_provider.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.linkedUserId,
    this.linkedHash,
    this.signedQuery = const {},
  });

  final String? linkedUserId;
  final String? linkedHash;
  final Map<String, String> signedQuery;

  static const routePath = '/verify-email';
  static const routeName = 'verify-email';

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  EmailVerificationStatus? _status;
  var _loadingStatus = true;
  var _resendBusy = false;
  WebViewController? _webController;
  var _webLoaded = false;
  var _handledSuccess = false;

  bool get _hasDeepLink =>
      widget.linkedUserId != null &&
      widget.linkedUserId!.isNotEmpty &&
      widget.linkedHash != null &&
      widget.linkedHash!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasDeepLink) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => _onWebViewPageFinished()),
        );
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadWebView());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Uri _signedVerificationUri() {
    final base = Env.apiBaseUrl.endsWith('/')
        ? Env.apiBaseUrl
        : '${Env.apiBaseUrl}/';
    final path =
        '${base}email/verify/${widget.linkedUserId}/${widget.linkedHash}';
    final baseUri = Uri.parse(path);
    if (widget.signedQuery.isEmpty) return baseUri;
    return baseUri.replace(
      queryParameters: {...baseUri.queryParameters, ...widget.signedQuery},
    );
  }

  Future<void> _loadWebView() async {
    if (!_hasDeepLink || _webController == null) return;
    final token = await ref.read(secureTokenStoreProvider).read();
    if (token == null || !mounted) return;
    setState(() => _webLoaded = true);
    await _webController!.loadRequest(
      _signedVerificationUri(),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  Future<void> _onWebViewPageFinished() async {
    if (_handledSuccess || !mounted) return;
    try {
      final raw = await _webController?.runJavaScriptReturningResult(
        'document.body.innerText',
      );
      if (raw == null || !mounted) return;
      final text = raw is String ? raw : raw.toString();
      final trimmed = text.trim();
      if (trimmed.startsWith('{')) {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        final data = map['data'];
        if (data is Map<String, dynamic> && data['email_verified'] == true) {
          _handledSuccess = true;
          await _afterVerified();
        }
      }
    } on Object {
      await _tryDioVerifyFallback();
    }
  }

  Future<void> _tryDioVerifyFallback() async {
    if (_handledSuccess || !_hasDeepLink) return;
    try {
      final result = await ref
          .read(authApiProvider)
          .verifyEmailSigned(
            userId: widget.linkedUserId!,
            hash: widget.linkedHash!,
            queryParameters: widget.signedQuery,
          );
      if (result.emailVerified) {
        _handledSuccess = true;
        await _afterVerified();
      }
    } on Object {
      // ignore — user can tap manual button
    }
  }

  Future<void> _afterVerified() async {
    await ref.read(authSessionProvider.notifier).refreshFromServer();
    if (!mounted) return;
    MemberFeedback.showSuccess(context, 'Email verified successfully.');
    context.go(MemberPaths.home);
  }

  Future<void> _loadStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final s = await ref.read(authApiProvider).getEmailVerificationStatus();
      if (mounted) setState(() => _status = s);
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resendBusy = true);
    try {
      await ref.read(authApiProvider).resendVerificationEmail();
      if (mounted) {
        MemberFeedback.showSuccess(
          context,
          'Email verification OTP sent successfully.',
        );
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _resendBusy = false);
    }
  }

  Future<void> _manualDioVerify() async {
    if (!_hasDeepLink) return;
    try {
      final result = await ref
          .read(authApiProvider)
          .verifyEmailSigned(
            userId: widget.linkedUserId!,
            hash: widget.linkedHash!,
            queryParameters: widget.signedQuery,
          );
      if (!mounted) return;
      if (result.emailVerified) {
        await _afterVerified();
      } else {
        MemberFeedback.showInfo(context, 'Verification did not complete.');
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberAuthLayout(
      title: 'Verify your email',
      actions: [
        TextButton(
          onPressed: () async {
            final ok = await showConfirmLogoutDialog(context);
            if (!ok || !context.mounted) return;
            await ref.read(authSessionProvider.notifier).logout();
            if (!context.mounted) return;
            context.go(LoginScreen.routePath);
          },
          child: const Text('Sign out'),
        ),
      ],
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(
            'Your email is verified using an email verification OTP before member features are unlocked.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'If you did not receive the code, resend email verification OTP below.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (_loadingStatus)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_status != null)
            MemberSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _status!.email ?? '—',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verified',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _status!.emailVerified ? 'Yes' : 'No',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _resendBusy ? null : _resend,
            child: Text(
              _resendBusy ? 'Sending…' : 'Resend email verification OTP',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadingStatus ? null : _loadStatus,
            child: const Text('Refresh status'),
          ),
          if (_hasDeepLink) ...[
            const SizedBox(height: 24),
            Text('Signed link', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (_webLoaded && _webController != null)
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: WebViewWidget(controller: _webController!),
                ),
              )
            else
              const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _manualDioVerify,
              child: const Text('Complete verification (direct request)'),
            ),
          ],
        ],
      ),
    );
  }
}
