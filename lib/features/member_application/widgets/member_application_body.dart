import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/app_dialog_shape.dart';
import '../../../widgets/terms_html_dialog.dart';
import '../../auth/models/user_resource.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../models/member_application_detail.dart';
import '../providers/member_application_workspace_provider.dart';

/// Membership application: create, edit, documents, submit (Pass 4).
class MemberApplicationBody extends ConsumerStatefulWidget {
  const MemberApplicationBody({super.key, required this.workspace, this.user});

  final MemberApplicationWorkspace workspace;
  final UserResource? user;

  @override
  ConsumerState<MemberApplicationBody> createState() =>
      _MemberApplicationBodyState();
}

class _MemberApplicationBodyState extends ConsumerState<MemberApplicationBody> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationality = TextEditingController(text: 'Nigeria');
  final _countryOfResidence = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankAccountOwnerName = TextEditingController();
  final _nextOfKinName = TextEditingController();
  final _nextOfKinPhone = TextEditingController();
  final _publisherOrg = TextEditingController();
  final _publisherTin = TextEditingController();
  final _publisherLocation = TextEditingController();
  final _publisherPostal = TextEditingController();
  final _publisherEmail = TextEditingController();
  final _publisherPhone = TextEditingController();
  final _notes = TextEditingController();
  final _memberProvidedId = TextEditingController();

  int? _associationId;
  String _applicantUiType = 'author';
  String? _memberAuthorType;
  String? _memberAuthorCategory;
  var _isDiaspora = false;
  var _consentAccepted = false;
  DateTime? _consentDate;
  var _saving = false;
  String? _uploadingDocType;

  MemberApplicationDetail? get _app => widget.workspace.application;

  bool get _editable => _app == null || _app!.canEdit;

  bool get _formIsPublisher => _applicantUiType == 'publisher';

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(covariant MemberApplicationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final appChanged =
        oldWidget.workspace.application?.id != widget.workspace.application?.id;
    final oldAssocSig = oldWidget.workspace.associations
        .map((a) => '${a.id}:${a.name}')
        .join('|');
    final newAssocSig = widget.workspace.associations
        .map((a) => '${a.id}:${a.name}')
        .join('|');
    final assocChanged = oldAssocSig != newAssocSig;
    final userChanged = oldWidget.user?.id != widget.user?.id;
    if (appChanged || (_app == null && (assocChanged || userChanged))) {
      _seed();
    }
  }

  void _seed() {
    final app = _app;
    final u = widget.user;
    final fallbackFirstFromName = (u?.name.trim().isNotEmpty ?? false)
        ? u!.name.trim().split(RegExp(r'\s+')).first
        : '';
    final fallbackLastFromName = (u?.name.trim().isNotEmpty ?? false)
        ? (() {
            final parts = u!.name.trim().split(RegExp(r'\s+'));
            if (parts.length < 2) return '';
            return parts.sublist(1).join(' ');
          })()
        : '';
    String preferred(String? primary, String? fallback, [String? backup]) {
      final a = primary?.trim() ?? '';
      if (a.isNotEmpty) return a;
      final b = fallback?.trim() ?? '';
      if (b.isNotEmpty) return b;
      final c = backup?.trim() ?? '';
      return c;
    }

    if (app != null) {
      _firstName.text = preferred(
        app.userFirstName,
        u?.firstName,
        fallbackFirstFromName,
      );
      _lastName.text = preferred(
        app.userLastName,
        u?.lastName,
        fallbackLastFromName,
      );
      _associationId = app.association?.id;
      _applicantUiType = app.isPublisherPath ? 'publisher' : 'author';
      _memberAuthorType = app.memberAuthorType ?? 'individual';
      _memberAuthorCategory = app.memberAuthorCategory ?? 'author';
      _nationality.text = app.nationality ?? 'Nigeria';
      _countryOfResidence.text = app.countryOfResidence ?? '';
      _isDiaspora = app.isDiaspora;
      _bankName.text = app.bankName ?? '';
      _bankAccountNumber.text = app.bankAccountNumber ?? '';
      _bankAccountOwnerName.text = app.bankAccountOwnerName ?? '';
      _nextOfKinName.text = app.nextOfKinName ?? '';
      _nextOfKinPhone.text = app.nextOfKinPhone ?? '';
      _publisherOrg.text = app.publisherOrganisationName ?? '';
      _publisherTin.text = app.publisherTin ?? '';
      _publisherLocation.text = app.publisherLocationAddress ?? '';
      _publisherPostal.text = app.publisherPostalAddress ?? '';
      _publisherEmail.text = app.publisherEmail ?? '';
      _publisherPhone.text = app.publisherPhone ?? '';
      _consentAccepted = app.consentAccepted;
      _notes.text = app.notes ?? '';
      _memberProvidedId.text = app.memberProvidedId ?? '';
      if (app.consentDate != null && app.consentDate!.isNotEmpty) {
        try {
          _consentDate = DateTime.parse(app.consentDate!);
        } on FormatException {
          _consentDate = null;
        }
      } else {
        _consentDate = null;
      }
    } else {
      _firstName.text = preferred(u?.firstName, fallbackFirstFromName);
      _lastName.text = preferred(u?.lastName, fallbackLastFromName);
      _associationId = widget.workspace.associations.isNotEmpty
          ? widget.workspace.associations.first.id
          : null;
      _applicantUiType = 'author';
      _memberAuthorType = 'individual';
      _memberAuthorCategory = 'author';
      _nationality.text = 'Nigeria';
      _countryOfResidence.text = '';
      _isDiaspora = false;
      _consentAccepted = false;
      _consentDate = null;
      _bankName.clear();
      _bankAccountNumber.clear();
      _bankAccountOwnerName.clear();
      _nextOfKinName.clear();
      _nextOfKinPhone.clear();
      _publisherOrg.clear();
      _publisherTin.clear();
      _publisherLocation.clear();
      _publisherPostal.clear();
      _publisherEmail.clear();
      _publisherPhone.clear();
      _notes.clear();
      _memberProvidedId.clear();
    }
    _ensureAssociationInList();
  }

  void _ensureAssociationInList() {
    final assoc = widget.workspace.associations;
    if (assoc.isEmpty) {
      _associationId = null;
      return;
    }
    if (_associationId == null || !assoc.any((a) => a.id == _associationId)) {
      _associationId = assoc.first.id;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nationality.dispose();
    _countryOfResidence.dispose();
    _bankName.dispose();
    _bankAccountNumber.dispose();
    _bankAccountOwnerName.dispose();
    _nextOfKinName.dispose();
    _nextOfKinPhone.dispose();
    _publisherOrg.dispose();
    _publisherTin.dispose();
    _publisherLocation.dispose();
    _publisherPostal.dispose();
    _publisherEmail.dispose();
    _publisherPhone.dispose();
    _notes.dispose();
    _memberProvidedId.dispose();
    super.dispose();
  }

  InputDecoration _fieldDec(ThemeData theme, {String? hint}) {
    final r = BorderRadius.circular(AppFormInput.borderRadius);
    final side = BorderSide(
      color: AppFormInput.outlineColor,
      width: AppFormInput.borderWidth,
    );
    final focusedSide = BorderSide(
      color: theme.colorScheme.primary,
      width: AppFormInput.borderWidth,
    );
    final errorSide = BorderSide(
      color: theme.colorScheme.error,
      width: AppFormInput.borderWidth,
    );
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelText: null,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(borderRadius: r, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: side),
      disabledBorder: OutlineInputBorder(borderRadius: r, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: focusedSide,
      ),
      errorBorder: OutlineInputBorder(borderRadius: r, borderSide: errorSide),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: errorSide,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _fieldLabel(String text, ThemeData theme, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionGap() => const SizedBox(height: 22);

  Widget _labeledTextField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    bool required = false,
    String? hint,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label, theme, required: required),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: _fieldDec(theme, hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _labeledDropdown<T>(
    ThemeData theme, {
    required String label,
    bool required = false,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label, theme, required: required),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            decoration: _fieldDec(theme, hint: hint),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item.value,
                    enabled: item.enabled,
                    onTap: item.onTap,
                    alignment: item.alignment,
                    child: DefaultTextStyle.merge(
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      child: item.child,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            iconEnabledColor: theme.colorScheme.onSurfaceVariant,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            dropdownColor: theme.colorScheme.surface,
          ),
        ],
      ),
    );
  }

  String _applicantTypeForApi() {
    if (_formIsPublisher) {
      if (_app?.applicantType == 'corporate_publisher') {
        return 'corporate_publisher';
      }
      return 'publisher';
    }
    return 'author';
  }

  Map<String, dynamic> _buildPayload() {
    final consentStr = _consentDate == null
        ? null
        : '${_consentDate!.year.toString().padLeft(4, '0')}-'
              '${_consentDate!.month.toString().padLeft(2, '0')}-'
              '${_consentDate!.day.toString().padLeft(2, '0')}';

    final base = <String, dynamic>{
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'association_id': _associationId,
      'applicant_type': _applicantTypeForApi(),
      'nationality': _nationality.text.trim(),
      'country_of_residence': _countryOfResidence.text.trim(),
      'is_diaspora': _isDiaspora,
      'bank_name': _bankName.text.trim(),
      'bank_account_number': _bankAccountNumber.text.trim(),
      'bank_account_owner_name': _bankAccountOwnerName.text.trim(),
      'consent_accepted': _consentAccepted,
      'consent_date': consentStr,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'member_provided_id': _memberProvidedId.text.trim().isEmpty
          ? null
          : _memberProvidedId.text.trim(),
    };

    if (_formIsPublisher) {
      base.addAll(<String, dynamic>{
        'publisher_organisation_name': _publisherOrg.text.trim(),
        'publisher_tin': _publisherTin.text.trim(),
        'publisher_location_address': _publisherLocation.text.trim(),
        'publisher_postal_address': _publisherPostal.text.trim(),
        'publisher_email': _publisherEmail.text.trim(),
        'publisher_phone': _publisherPhone.text.trim(),
      });
    } else {
      base.addAll(<String, dynamic>{
        'member_author_type': _memberAuthorType,
        'member_author_category': _memberAuthorCategory,
        'next_of_kin_name': _nextOfKinName.text.trim(),
        'next_of_kin_phone': _nextOfKinPhone.text.trim(),
      });
    }
    return base;
  }

  Future<void> _save() async {
    if (!_editable) return;
    final validationError = _validateForSave();
    if (validationError != null) {
      MemberFeedback.showInfo(context, validationError);
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(memberApplicationApiProvider);
      final payload = _buildPayload();
      if (_app == null) {
        await api.createApplication(payload);
      } else {
        await api.updateApplication(_app!.id, payload);
      }
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Application saved.');
        ref.invalidate(memberApplicationWorkspaceProvider);
        await ref.read(memberApplicationWorkspaceProvider.future);
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final app = _app;
    if (app == null || !_editable || !_liveCanSubmit()) return;
    final validationError = _validateForSave();
    if (validationError != null) {
      MemberFeedback.showInfo(context, validationError);
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(memberApplicationApiProvider);
      await api.updateApplication(app.id, _buildPayload());
      await api.submitApplication(app.id);
      if (mounted) {
        ref.invalidate(memberApplicationWorkspaceProvider);
        await ref.read(memberApplicationWorkspaceProvider.future);
        await _showSubmissionSuccessDialog();
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseDocumentSource(String documentType) async {
    final app = _app;
    if (app == null) {
      MemberFeedback.showInfo(
        context,
        'Save your application before uploading documents.',
      );
      return;
    }
    if (!_editable) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Choose file'),
              subtitle: const Text('PDF or image from your device'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('Camera (saved as JPEG)'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    if (source == 'file') {
      await _pickFileAndUpload(documentType);
    } else if (source == 'camera') {
      await _takePhotoAndUpload(documentType);
    }
  }

  Future<void> _performDocumentUpload({
    required String documentType,
    required String fileName,
    String? filePath,
    List<int>? fileBytes,
  }) async {
    final app = _app;
    if (app == null || !_editable) return;

    setState(() => _uploadingDocType = documentType);
    try {
      await ref
          .read(memberApplicationApiProvider)
          .uploadDocument(
            applicationId: app.id,
            documentType: documentType,
            fileName: fileName,
            filePath: filePath,
            fileBytes: fileBytes,
          );
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Document uploaded.');
        ref.invalidate(memberApplicationWorkspaceProvider);
        await ref.read(memberApplicationWorkspaceProvider.future);
      }
    } on ApiException catch (e) {
      if (mounted) {
        MemberFeedback.showError(
          context,
          e,
          fallback: MemberFeedback.fileUploadFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  Future<void> _pickFileAndUpload(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final path = f.path;
    final bytes = f.bytes;
    if ((bytes == null || bytes.isEmpty) && (path == null || path.isEmpty)) {
      if (mounted) {
        MemberFeedback.showInfo(context, 'Could not read the selected file.');
      }
      return;
    }

    await _performDocumentUpload(
      documentType: documentType,
      fileName: f.name,
      filePath: path,
      fileBytes: bytes,
    );
  }

  Future<void> _takePhotoAndUpload(String documentType) async {
    final picker = ImagePicker();
    XFile? shot;
    try {
      shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 4096,
        maxHeight: 4096,
      );
    } catch (_) {
      if (mounted) {
        MemberFeedback.showInfo(
          context,
          'Could not open the camera. Check permission in device settings.',
        );
      }
      return;
    }
    if (shot == null || !mounted) return;

    late final List<int> bytes;
    try {
      bytes = await shot.readAsBytes();
    } catch (_) {
      if (mounted) {
        MemberFeedback.showInfo(context, 'Could not read the photo.');
      }
      return;
    }
    if (bytes.isEmpty) {
      if (mounted) {
        MemberFeedback.showInfo(context, 'Could not read the photo.');
      }
      return;
    }

    var name = shot.name;
    if (name.isEmpty ||
        !RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(name)) {
      name =
          'photo_${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    await _performDocumentUpload(
      documentType: documentType,
      fileName: name,
      fileBytes: bytes,
    );
  }

  Future<void> _confirmDelete(MemberApplicationDocumentRow doc) async {
    final app = _app;
    if (app == null || !_editable) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: appDialogShape(),
        title: const Text('Remove document?'),
        content: Text('Remove ${doc.fileName ?? doc.documentType}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(memberApplicationApiProvider)
          .deleteDocument(applicationId: app.id, documentId: doc.id);
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Document removed.');
        ref.invalidate(memberApplicationWorkspaceProvider);
        await ref.read(memberApplicationWorkspaceProvider.future);
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  String? _validateForSave() {
    final fn = _firstName.text.trim();
    final ln = _lastName.text.trim();
    if (fn.isEmpty) return 'First name is required.';
    if (fn.length > 100) return 'First name must be at most 100 characters.';
    if (ln.isEmpty) return 'Last name is required.';
    if (ln.length > 100) return 'Last name must be at most 100 characters.';
    if (_associationId == null || _associationId! < 1) {
      return 'Association is required.';
    }
    if (_nationality.text.trim().length < 2) return 'Nationality is required.';
    if (_countryOfResidence.text.trim().length < 2) {
      return 'Country of residence is required.';
    }
    if (_bankName.text.trim().length < 2) return 'Bank name is required.';
    if (_bankAccountNumber.text.trim().length < 4) {
      return 'Bank account number is required.';
    }
    if (_bankAccountOwnerName.text.trim().length < 2) {
      return 'Account owner name is required.';
    }
    if (!_consentAccepted) {
      return 'Please read and accept the data protection policy before saving.';
    }
    if (_consentDate == null) return 'Consent date is required.';
    if (!_formIsPublisher) {
      if (_memberAuthorType == null || _memberAuthorType!.trim().isEmpty) {
        return 'Author type is required.';
      }
      if (_memberAuthorCategory == null ||
          _memberAuthorCategory!.trim().isEmpty) {
        return 'Author category is required.';
      }
      if (_nextOfKinName.text.trim().isEmpty) {
        return 'Next of kin name is required.';
      }
      if (_nextOfKinPhone.text.trim().isEmpty) {
        return 'Next of kin contact number is required.';
      }
    } else {
      if (_publisherOrg.text.trim().isEmpty) {
        return 'Organization name is required.';
      }
      if (_publisherTin.text.trim().isEmpty) {
        return 'Tax Identification Number is required.';
      }
      if (_publisherLocation.text.trim().isEmpty) {
        return 'Location address is required.';
      }
      if (_publisherPostal.text.trim().isEmpty) {
        return 'Postal address is required.';
      }
      final pe = _publisherEmail.text.trim();
      if (pe.isEmpty) return 'Organization email is required.';
      if (!_looksLikeValidEmail(pe)) {
        return 'Enter a valid organization email.';
      }
      if (_publisherPhone.text.trim().isEmpty) {
        return 'Organization phone number is required.';
      }
    }
    if (_notes.text.trim().length > 1000) {
      return 'Notes must be at most 1000 characters.';
    }
    if (_memberProvidedId.text.trim().length > 100) {
      return 'Member reference ID must be at most 100 characters.';
    }
    return null;
  }

  bool _looksLikeValidEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  Future<void> _openDataProtectionTerms() async {
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

  String _associationDisplayNameForMessage() {
    final fromApp = (_app?.association?.name ?? '').trim();
    if (fromApp.isNotEmpty) return fromApp;
    final id = _associationId;
    if (id != null) {
      for (final a in widget.workspace.associations) {
        if (a.id == id) return a.name;
      }
    }
    return 'your association';
  }

  Future<void> _showSubmissionSuccessDialog() async {
    final assocName = _associationDisplayNameForMessage();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: appDialogShape(),
        title: const Text('Application submitted'),
        content: Text(
          'Your membership application is now under affiliation validation. '
          '$assocName will validate first, then our admin will review your application. '
          'You will receive email and in-app updates if admin requests changes, rejects, or approves your application.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMandateData() async {
    final app = _app;
    if (app == null || app.applicationStatus != 'approved') return;
    try {
      final response = await ref
          .read(memberApplicationApiProvider)
          .downloadMandate(app.id);
      final content = utf8.decode(response.data ?? const <int>[]);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: appDialogShape(),
          title: const Text('Mandate form data'),
          content: SingleChildScrollView(
            child: SelectableText(
              content.isEmpty ? 'No mandate data returned.' : content,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (mounted)
                  MemberFeedback.showSuccess(context, 'Mandate data copied.');
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  String _formatIsoDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '—';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(iso));
    } on FormatException {
      return iso;
    }
  }

  bool _missingRequiredDocuments(MemberApplicationDetail app) {
    return !app.hasProofOfId || !app.hasProofOfAddress;
  }

  String _missingDocumentLabels(MemberApplicationDetail app) {
    final missing = <String>[];
    if (!app.hasProofOfId) missing.add('Proof of ID');
    if (!app.hasProofOfAddress) missing.add('Proof of address');
    return missing.join(', ');
  }

  bool _liveCanSubmit() {
    final app = _app;
    if (app == null || !_editable) return false;
    if (!_consentAccepted || _consentDate == null) return false;
    final hasId = app.documents.any((d) => d.documentType == 'proof_of_id');
    final hasAddr = app.documents.any(
      (d) => d.documentType == 'proof_of_address',
    );
    return hasId && hasAddr;
  }

  Future<void> _pickConsentDate() async {
    final now = DateTime.now();
    final initial = _consentDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _consentDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = _app;
    final assoc = widget.workspace.associations;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(memberApplicationWorkspaceProvider);
        await ref.read(memberApplicationWorkspaceProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          if (app != null) ...[
            _sectionGap(),
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current status',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _applicationStatusPill(
                          theme,
                          label: 'Application',
                          value: _humanize(app.applicationStatus),
                          tone: _StatusPillTone.application,
                        ),
                        if (app.submissionStage != null)
                          _applicationStatusPill(
                            theme,
                            label: 'Stage',
                            value: _humanize(app.submissionStage!),
                            tone: _StatusPillTone.stage,
                          ),
                        if (app.affiliationStatus != null &&
                            app.affiliationStatus!.isNotEmpty)
                          _applicationStatusPill(
                            theme,
                            label: 'Affiliation',
                            value: _humanize(app.affiliationStatus!),
                            tone: _StatusPillTone.stage,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _applicationStatusRow(
                      theme,
                      label: 'Submitted',
                      value: _formatIsoDate(app.submittedAt),
                    ),
                    _applicationStatusRow(
                      theme,
                      label: 'Reviewed',
                      value: _formatIsoDate(app.reviewedAt),
                    ),
                    _applicationStatusRow(
                      theme,
                      label: 'Association',
                      value: app.association?.name ?? 'Not selected yet',
                    ),
                    if (app.applicationReference != null &&
                        app.applicationReference!.trim().isNotEmpty)
                      _applicationStatusRow(
                        theme,
                        label: 'Reference',
                        value: app.applicationReference!,
                        valueMuted: true,
                      ),
                  ],
                ),
              ),
            ),
            if (!_editable)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFFFF7E6)
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE7D7B8)
                          : theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Editing is locked. You can still review your answers and uploaded documents below.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          if (app != null && _editable && _missingRequiredDocuments(app)) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: theme.colorScheme.error,
                  width: theme.brightness == Brightness.light ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload all required application documents before submitting: '
                        '${_missingDocumentLabels(app)}.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _sectionGap(),
          _numberedSection(
            context,
            badge: '1',
            title: 'Consent & mandate',
            description:
                'Confirm you have read the data protection policy before continuing.',
            children: [
              Text(
                'Having read the data protection policy, I give consent for the use of my '
                'personal data, and the transfer of data overseas, for the purpose outlined in '
                'the policy.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _editable ? _openDataProtectionTerms : null,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read the policy',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'REPRONIG shall not be held liable for any damages caused by your failure to '
                'read this policy before submitting your data.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: Checkbox(
                      value: _consentAccepted,
                      onChanged: _editable
                          ? (v) => setState(() => _consentAccepted = v ?? false)
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _editable
                          ? () => setState(
                              () => _consentAccepted = !_consentAccepted,
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 10,
                          end: 4,
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              color: theme.colorScheme.onSurface,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'I confirm the above and that I have read the data protection policy before continuing.',
                              ),
                              TextSpan(
                                text: ' *',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _fieldLabel('Consent date', theme, required: true),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  side: BorderSide(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFC5CCD6)
                        : theme.colorScheme.outline.withValues(alpha: 0.45),
                  ),
                ),
                title: Text(
                  _consentDate == null
                      ? 'Choose date'
                      : DateFormat.yMMMd().format(_consentDate!),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                trailing: _editable
                    ? TextButton(
                        onPressed: _pickConsentDate,
                        child: const Text('Choose'),
                      )
                    : null,
              ),
              if (_consentDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Required before submission.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          _sectionGap(),
          _numberedSection(
            context,
            badge: '2',
            title: 'Applicant & Association details',
            description: 'Choose your association and how you are applying.',
            children: [
              _labeledTextField(
                theme,
                label: 'First name',
                controller: _firstName,
                required: true,
                enabled: _editable,
                textCapitalization: TextCapitalization.words,
              ),
              _labeledTextField(
                theme,
                label: 'Last name',
                controller: _lastName,
                required: true,
                enabled: _editable,
                textCapitalization: TextCapitalization.words,
              ),
              if (assoc.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text(
                    'No collecting societies are available. Pull to refresh or check your connection.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              else
                _labeledDropdown<int>(
                  theme,
                  label: 'Association',
                  required: true,
                  value: _associationId,
                  hint: 'Select association',
                  items: [
                    for (final a in assoc)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: _editable
                      ? (v) => setState(() => _associationId = v)
                      : null,
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Applicant type', theme, required: true),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'author', label: Text('Author')),
                        ButtonSegment(
                          value: 'publisher',
                          label: Text('Publisher'),
                        ),
                      ],
                      selected: {_applicantUiType},
                      onSelectionChanged: _editable
                          ? (s) => setState(() => _applicantUiType = s.first)
                          : (_) {},
                    ),
                  ],
                ),
              ),
              if (!_formIsPublisher) ...[
                _labeledDropdown<String>(
                  theme,
                  label: 'Author type',
                  required: true,
                  value: _memberAuthorType,
                  hint: 'Select author type',
                  items: const [
                    DropdownMenuItem(
                      value: 'individual',
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(
                      value: 'corporate',
                      child: Text('Corporate'),
                    ),
                    DropdownMenuItem(value: 'agent', child: Text('Agent')),
                  ],
                  onChanged: _editable
                      ? (v) => setState(() => _memberAuthorType = v)
                      : null,
                ),
                _labeledDropdown<String>(
                  theme,
                  label: 'Category',
                  required: true,
                  value: _memberAuthorCategory,
                  hint: 'Select category',
                  items: const [
                    DropdownMenuItem(value: 'author', child: Text('Author')),
                    DropdownMenuItem(
                      value: 'journalist',
                      child: Text('Journalist'),
                    ),
                    DropdownMenuItem(
                      value: 'photographer',
                      child: Text('Photographer'),
                    ),
                    DropdownMenuItem(
                      value: 'illustrator',
                      child: Text('Illustrator'),
                    ),
                    DropdownMenuItem(value: 'carver', child: Text('Carver')),
                    DropdownMenuItem(value: 'painter', child: Text('Painter')),
                    DropdownMenuItem(
                      value: 'sculptor',
                      child: Text('Sculptor'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: _editable
                      ? (v) => setState(() => _memberAuthorCategory = v)
                      : null,
                ),
                _labeledTextField(
                  theme,
                  label: 'Nationality',
                  controller: _nationality,
                  required: true,
                  enabled: _editable,
                  hint: 'e.g. Nigeria',
                ),
                _labeledTextField(
                  theme,
                  label: 'Name of next of kin',
                  controller: _nextOfKinName,
                  required: true,
                  enabled: _editable,
                  textCapitalization: TextCapitalization.words,
                ),
                _labeledTextField(
                  theme,
                  label: 'Next of kin contact number',
                  controller: _nextOfKinPhone,
                  required: true,
                  enabled: _editable,
                  keyboardType: TextInputType.phone,
                ),
              ],
              if (_formIsPublisher) ...[
                _labeledTextField(
                  theme,
                  label: 'Name of organization',
                  controller: _publisherOrg,
                  required: true,
                  enabled: _editable,
                ),
                _labeledTextField(
                  theme,
                  label: 'Tax Identification Number (TIN)',
                  controller: _publisherTin,
                  required: true,
                  enabled: _editable,
                ),
                _labeledTextField(
                  theme,
                  label: 'Location address',
                  controller: _publisherLocation,
                  required: true,
                  enabled: _editable,
                  maxLines: 2,
                ),
                _labeledTextField(
                  theme,
                  label: 'Postal address',
                  controller: _publisherPostal,
                  required: true,
                  enabled: _editable,
                  maxLines: 2,
                ),
                _labeledTextField(
                  theme,
                  label: 'Organization email',
                  controller: _publisherEmail,
                  required: true,
                  enabled: _editable,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'name@organization.com',
                ),
                _labeledTextField(
                  theme,
                  label: 'Organization phone number',
                  controller: _publisherPhone,
                  required: true,
                  enabled: _editable,
                  keyboardType: TextInputType.phone,
                ),
              ],
              _labeledTextField(
                theme,
                label: 'Country of residence',
                controller: _countryOfResidence,
                required: true,
                enabled: _editable,
                textCapitalization: TextCapitalization.words,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Switch(
                      value: _isDiaspora,
                      onChanged: _editable
                          ? (v) => setState(() => _isDiaspora = v)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'I am applying from the diaspora',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _labeledTextField(
                theme,
                label: 'Your member / reference ID (optional)',
                controller: _memberProvidedId,
                enabled: _editable,
                hint: 'e.g. Association membership ID',
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'If your institution or society gave you an ID, enter it here so reviewers can match your record.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          _sectionGap(),
          _numberedSection(
            context,
            badge: '3',
            title: 'Royalty payment account',
            description: 'Bank details for royalty payouts.',
            children: [
              _labeledTextField(
                theme,
                label: 'Bank name',
                controller: _bankName,
                required: true,
                enabled: _editable,
              ),
              _labeledTextField(
                theme,
                label: 'Bank account number',
                controller: _bankAccountNumber,
                required: true,
                enabled: _editable,
              ),
              _labeledTextField(
                theme,
                label: 'Account owner name',
                controller: _bankAccountOwnerName,
                required: true,
                enabled: _editable,
              ),
            ],
          ),
          _sectionGap(),
          _numberedSection(
            context,
            badge: '4',
            title: 'Notes',
            description: 'Optional note for reviewer.',
            children: [
              _labeledTextField(
                theme,
                label: '',
                controller: _notes,
                enabled: _editable,
                maxLines: 4,
                hint: 'Type here',
              ),
            ],
          ),
          _sectionGap(),
          _numberedSection(
            context,
            badge: '5',
            title: 'Application documents',
            description:
                'Each mandatory document has its own upload control. PDF, JPG, JPEG, or PNG — max 10 MB.',
            children: [
              if (app == null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFC5CCD6)
                          : theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Create your application first (save at the bottom). '
                      'You can upload documents after the application record exists.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              if (app == null) const SizedBox(height: 18),
              _docRow(
                context,
                theme,
                label: 'Proof of ID',
                isRequired: true,
                hint:
                    "This can be NIN, International Passport, Driver's Licence, or Voter's Card.",
                type: 'proof_of_id',
                doc: _docFor('proof_of_id'),
              ),
              const SizedBox(height: 6),
              _docRow(
                context,
                theme,
                label: 'Proof of address',
                isRequired: true,
                hint:
                    'This can be a utility bill, bank statement, or phone bill.',
                type: 'proof_of_address',
                doc: _docFor('proof_of_address'),
              ),
            ],
          ),
          _sectionGap(),
          if (_editable)
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Text(
                              _app == null
                                  ? 'Create application'
                                  : 'Update application',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    if (_app != null && _app!.canEdit) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        onPressed: (!_liveCanSubmit() || _saving)
                            ? null
                            : _submit,
                        child: Text(
                          'Submit application',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!_liveCanSubmit())
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Upload proof of ID and proof of address, accept the policy, '
                            'and set your consent date to enable submission.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          if (app != null && app.applicationStatus == 'approved') ...[
            _sectionGap(),
            FilledButton.tonal(
              onPressed: _downloadMandateData,
              child: const Text('Download mandate form data'),
            ),
          ],
        ],
      ),
    );
  }

  MemberApplicationDocumentRow? _docFor(String type) {
    final docs = _app?.documents ?? const [];
    for (final d in docs) {
      if (d.documentType == type) return d;
    }
    return null;
  }

  Widget _numberedSection(
    BuildContext context, {
    required String badge,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final headingColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    final subColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    return DecoratedBox(
      decoration: AppMemberSurfaces.section(theme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: headingColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _docRow(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isRequired,
    required String hint,
    required String type,
    required MemberApplicationDocumentRow? doc,
  }) {
    final busy = _uploadingDocType == type;
    final headingColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    final subColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: AppMemberSurfaces.inset(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: headingColor,
                      ),
                    ),
                  ),
                  if (isRequired)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Required',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hint,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF, JPG, JPEG, or PNG. Max 10 MB.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (doc != null) ...[
                const SizedBox(height: 10),
                Text(
                  doc.fileName ?? 'Uploaded',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final u = Uri.tryParse(doc.fileUrl!);
                          if (u != null && await canLaunchUrl(u)) {
                            await launchUrl(
                              u,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(
                          'Open',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (_editable)
                      TextButton(
                        onPressed: busy ? null : () => _confirmDelete(doc),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Not uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_editable) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: btnShape,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: busy
                          ? null
                          : () => _chooseDocumentSource(type),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  doc != null
                                      ? Icons.upload_file
                                      : Icons.add_photo_alternate_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  doc != null ? 'Replace file' : 'Upload file',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Flat status line (no gradients) — label / value with comfortable line height.
  Widget _applicationStatusRow(
    ThemeData theme, {
    required String label,
    required String value,
    bool valueMuted = false,
  }) {
    final vColor = valueMuted
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.42,
                letterSpacing: 0.02,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.52,
                color: vColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationStatusPill(
    ThemeData theme, {
    required String label,
    required String value,
    required _StatusPillTone tone,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final Color bg = switch (tone) {
      _StatusPillTone.application =>
        (isDark ? AppColors.primary : AppColors.primary).withValues(
          alpha: isDark ? 0.26 : 0.12,
        ),
      _StatusPillTone.stage =>
        (isDark ? AppColors.brandGold : AppColors.brandGold).withValues(
          alpha: isDark ? 0.22 : 0.14,
        ),
    };

    final Color border = switch (tone) {
      _StatusPillTone.application =>
        (isDark ? AppColors.primary : AppColors.primary).withValues(
          alpha: isDark ? 0.35 : 0.28,
        ),
      _StatusPillTone.stage =>
        (isDark ? AppColors.brandGold : AppColors.brandGold).withValues(
          alpha: isDark ? 0.40 : 0.30,
        ),
    };

    final Color labelColor = cs.onSurface.withValues(alpha: 0.72);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.75,
              height: 1.2,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  static String _humanize(String s) => s.replaceAll('_', ' ');
}

enum _StatusPillTone { application, stage }
