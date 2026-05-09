import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../../widgets/terms_html_dialog.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../models/member_work.dart';
import '../models/work_contributor.dart';
import '../providers/works_providers.dart';
import '../work_consent_copy.dart';
import '../work_field_options.dart';

class WorkEditorScreen extends ConsumerStatefulWidget {
  const WorkEditorScreen({super.key, this.workId});

  /// `null` = create new work.
  final int? workId;

  static const newRoutePath = '/member/works/new';

  static String editRoutePath(int id) => '/member/works/view/$id/edit';

  static const routeNameNew = 'member-work-new';
  static const routeNameEdit = 'member-work-edit';

  @override
  ConsumerState<WorkEditorScreen> createState() => _WorkEditorScreenState();
}

class _WorkEditorScreenState extends ConsumerState<WorkEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _year = TextEditingController();
  final _synopsis = TextEditingController();
  final _identifierValue = TextEditingController();
  final _doi = TextEditingController();
  final _publisherName = TextEditingController();
  final _targetMarketOther = TextEditingController();
  final _otherWorkType = TextEditingController();
  final _notes = TextEditingController();
  final _contribName = TextEditingController();
  final _contribRole = TextEditingController(text: 'Author');
  final _contribPct = TextEditingController();
  final _contribTerritory = TextEditingController(text: 'Nigeria');

  List<LanguageOption> _languages = const [];
  var _loading = true;
  var _saving = false;

  String _typeOfWork = WorkFieldOptions.workTypes[1].value;
  String _workFormat = WorkFieldOptions.workFormats[0].value;
  String _identifierType = WorkFieldOptions.identifierTypes[0].value;
  String _targetMarket = WorkFieldOptions.targetMarkets[3].value;
  String _productionStatus = 'yes';
  String? _primaryLanguageName;
  var _agreementAccepted = false;
  DateTime? _consentDate;

  /// New work only — aligned with web `workFileTypeOptions`.
  Uint8List? _coverBytes;
  String? _coverName;
  Uint8List? _copyrightBytes;
  String? _copyrightName;
  Uint8List? _proofBytes;
  String? _proofName;

  List<WorkContributorDraft> _contributors = [];
  String _contribRightType = 'exclusive';
  String? _editingContributorKey;
  String? _contributorError;
  MemberWork? _loadedWork;

  bool get _isNew => widget.workId == null;

  /// Related files picker is shown for new works and while editing any loaded draft/work.
  bool get _showRelatedFilesSection =>
      _isNew || (_loadedWork != null && _loadedWork!.canEdit);

  String? _attachedFileLabel(String fileType) {
    String? name;
    for (final f in _loadedWork?.attachedFiles ?? const []) {
      if (f.fileType == fileType) {
        name = f.fileName.isNotEmpty ? f.fileName : name;
      }
    }
    return name;
  }

  /// Shown filename: pending upload wins, otherwise last server attachment for type.
  String? _pendingOrAttachedName({
    required Uint8List? pendingBytes,
    required String? pendingName,
    required String fileType,
  }) {
    if (pendingBytes != null &&
        pendingName != null &&
        pendingName.trim().isNotEmpty) {
      return pendingName;
    }
    return _attachedFileLabel(fileType);
  }

  bool get _hasCoverReadyToSubmit {
    final local =
        _coverBytes != null &&
        (_coverName != null && _isAllowedCoverFilename(_coverName!));
    if (local) return true;
    final n = _attachedFileLabel('cover_image');
    return n != null && _isAllowedCoverFilename(n);
  }

  bool _isAllowedCoverFilename(String filename) {
    final n = filename.trim().toLowerCase();
    return n.endsWith('.png') || n.endsWith('.jpg') || n.endsWith('.jpeg');
  }

  double get _contributorTotalOwnership =>
      _contributors.fold(0.0, (s, c) => s + c.ownershipPercentage);

  bool get _ownershipWithinLimit => _contributorTotalOwnership <= 100.001;

  bool get _ownershipEqualsHundred =>
      _contributors.isEmpty || (_contributorTotalOwnership - 100).abs() < 0.001;

  bool get _hideContributorFormWhenComplete =>
      _contributors.isNotEmpty &&
      (_contributorTotalOwnership - 100).abs() < 0.001;

  @override
  void initState() {
    super.initState();
    _year.text = '${DateTime.now().year}';
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _year.dispose();
    _synopsis.dispose();
    _identifierValue.dispose();
    _doi.dispose();
    _publisherName.dispose();
    _targetMarketOther.dispose();
    _otherWorkType.dispose();
    _notes.dispose();
    _contribName.dispose();
    _contribRole.dispose();
    _contribPct.dispose();
    _contribTerritory.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final langs = await ref.read(worksApiProvider).listLanguages();
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _primaryLanguageName ??= langs.isNotEmpty
            ? langs.first.name
            : 'English';
      });

      if (widget.workId != null) {
        final w = await ref.read(worksApiProvider).getWork(widget.workId!);
        if (!w.canEdit) {
          if (mounted) {
            MemberFeedback.showInfo(
              context,
              'This work is locked. Request admin approval before editing.',
            );
            context.pop();
          }
          return;
        }
        if (!mounted) return;
        setState(() {
          _loadedWork = w;
          _typeOfWork = w.typeOfWork ?? _typeOfWork;
          _title.text = w.title;
          _subtitle.text = w.subtitle ?? '';
          _year.text = '${w.publicationYear ?? DateTime.now().year}';
          _synopsis.text = w.synopsis ?? '';
          _primaryLanguageName = w.primaryLanguage ?? _primaryLanguageName;
          _workFormat = w.workFormat ?? _workFormat;
          _identifierType = w.identifierType ?? _identifierType;
          _identifierValue.text = w.identifierValue ?? '';
          _doi.text = w.doi ?? '';
          _publisherName.text = w.publisherName ?? '';
          _targetMarket = w.targetMarket ?? _targetMarket;
          _targetMarketOther.text = w.targetMarketOther ?? '';
          _productionStatus = w.productionStatus ?? _productionStatus;
          _agreementAccepted = w.agreementAccepted;
          _otherWorkType.text = w.otherWorkType ?? '';
          _notes.text = w.notes ?? '';
          if (w.dateOfConsent != null && w.dateOfConsent!.isNotEmpty) {
            try {
              _consentDate = DateTime.parse(w.dateOfConsent!);
            } on FormatException {
              _consentDate = null;
            }
          }
          _contributors = w.contributors
              .map(WorkContributorDraft.fromContributor)
              .toList();
        });
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  static const double _kRelatedFileButtonRadius = 5;

  static bool _allowsCameraForExtensions(List<String> extensions) {
    const img = {'png', 'jpg', 'jpeg'};
    return extensions.any((e) => img.contains(e.toLowerCase()));
  }

  static bool _isImageOnlyExtensions(List<String> extensions) {
    if (extensions.isEmpty) return false;
    const img = {'png', 'jpg', 'jpeg'};
    final normalized = extensions.map((e) => e.toLowerCase()).toSet();
    return normalized.every(img.contains);
  }

  void _assignWorkFileBytes(String fileType, Uint8List bytes, String name) {
    setState(() {
      if (fileType == 'cover_image') {
        _coverBytes = bytes;
        _coverName = name;
      } else if (fileType == 'copyright_page') {
        _copyrightBytes = bytes;
        _copyrightName = name;
      } else if (fileType == 'proof_of_ownership') {
        _proofBytes = bytes;
        _proofName = name;
      }
    });
  }

  Future<void> _pickWorkFile({
    required String fileType,
    required List<String> extensions,
  }) async {
    if (_isImageOnlyExtensions(extensions)) {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        MemberFeedback.showInfo(context, 'Could not read the selected photo.');
        return;
      }
      var name = image.name;
      if (!name.contains('.')) {
        name = '$name.jpg';
      }
      _assignWorkFileBytes(fileType, bytes, name);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        MemberFeedback.showInfo(context, 'Could not read the selected file.');
      }
      return;
    }
    if (!mounted) return;
    _assignWorkFileBytes(fileType, bytes, f.name);
  }

  Future<void> _pickWorkPhotoFromCamera({
    required String fileType,
    required List<String> extensions,
  }) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty) {
      MemberFeedback.showInfo(context, 'Could not read the captured photo.');
      return;
    }
    var name = x.name;
    if (!name.toLowerCase().endsWith('.jpg') &&
        !name.toLowerCase().endsWith('.jpeg') &&
        !name.toLowerCase().endsWith('.png')) {
      name = '$name.jpg';
    }
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final allowed = extensions.map((e) => e.toLowerCase()).toSet();
    if (!allowed.contains(ext) &&
        !(ext == 'jpg' && allowed.contains('jpeg')) &&
        !(ext == 'jpeg' && allowed.contains('jpg'))) {
      if (mounted) {
        MemberFeedback.showInfo(
          context,
          'Captured image type (.$ext) is not allowed for this slot. '
          'Allowed: ${extensions.join(", ")}.',
        );
      }
      return;
    }
    _assignWorkFileBytes(fileType, bytes, name);
  }

  Future<void> _showFullTerms() async {
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

  Map<String, dynamic> _payload() {
    final year = int.tryParse(_year.text.trim());
    final consentStr = _consentDate == null
        ? null
        : '${_consentDate!.year.toString().padLeft(4, '0')}-'
              '${_consentDate!.month.toString().padLeft(2, '0')}-'
              '${_consentDate!.day.toString().padLeft(2, '0')}';

    return <String, dynamic>{
      'type_of_work': _typeOfWork,
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      if (year != null) 'publication_year': year,
      'synopsis': _synopsis.text.trim().isEmpty ? null : _synopsis.text.trim(),
      'primary_language': _primaryLanguageName ?? 'English',
      'work_format': _workFormat,
      'identifier_type': _identifierType,
      'identifier_value': _identifierValue.text.trim().isEmpty
          ? null
          : _identifierValue.text.trim(),
      'doi': _doi.text.trim().isEmpty ? null : _doi.text.trim(),
      'publisher_name': _publisherName.text.trim().isEmpty
          ? null
          : _publisherName.text.trim(),
      'target_market': _targetMarket,
      'target_market_other': _targetMarketOther.text.trim().isEmpty
          ? null
          : _targetMarketOther.text.trim(),
      'production_status': _productionStatus,
      'agreement_accepted': _agreementAccepted,
      'date_of_consent': consentStr,
      'other_work_type': _otherWorkType.text.trim().isEmpty
          ? null
          : _otherWorkType.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
  }

  Future<void> _uploadPendingFiles(int workId) async {
    final api = ref.read(worksApiProvider);
    if (_coverBytes != null && _coverName != null) {
      await api.uploadWorkFile(
        workId,
        fileType: 'cover_image',
        bytes: _coverBytes!.toList(),
        filename: _coverName!,
      );
    }
    if (_copyrightBytes != null && _copyrightName != null) {
      await api.uploadWorkFile(
        workId,
        fileType: 'copyright_page',
        bytes: _copyrightBytes!.toList(),
        filename: _copyrightName!,
      );
    }
    if (_proofBytes != null && _proofName != null) {
      await api.uploadWorkFile(
        workId,
        fileType: 'proof_of_ownership',
        bytes: _proofBytes!.toList(),
        filename: _proofName!,
      );
    }
  }

  void _resetContributorEditor() {
    _contribName.clear();
    _contribRole.text = 'Author';
    _contribRightType = 'exclusive';
    _contribPct.clear();
    _contribTerritory.text = 'Nigeria';
    _editingContributorKey = null;
    _contributorError = null;
  }

  String? _validateContributorDraft({String? excludingKey}) {
    final name = _contribName.text.trim();
    final role = _contribRole.text.trim();
    final pct = double.tryParse(_contribPct.text.trim());
    if (name.isEmpty) return 'Contributor name is required.';
    if (role.isEmpty) return 'Contributor role is required.';
    if (pct == null || pct <= 0) {
      return 'Ownership percentage must be greater than 0.';
    }
    if (pct > 100) return 'Ownership percentage cannot exceed 100%.';
    var other = 0.0;
    for (final c in _contributors) {
      if (c.key == excludingKey) continue;
      other += c.ownershipPercentage;
    }
    if (other + pct > 100.001) {
      return 'Contributor ownership percentages cannot exceed 100% in total.';
    }
    return null;
  }

  void _upsertContributorDraft() {
    final err = _validateContributorDraft(excludingKey: _editingContributorKey);
    if (err != null) {
      setState(() => _contributorError = err);
      return;
    }
    final pct = double.tryParse(_contribPct.text.trim())!;
    WorkContributorDraft? editingRow;
    if (_editingContributorKey != null) {
      for (final c in _contributors) {
        if (c.key == _editingContributorKey) {
          editingRow = c;
          break;
        }
      }
    }
    final draft = WorkContributorDraft(
      key:
          editingRow?.key ??
          'new-${DateTime.now().millisecondsSinceEpoch}-${_contributors.length}',
      existingId: editingRow?.existingId,
      memberId: editingRow?.memberId,
      contributorName: _contribName.text.trim(),
      contributorRole: _contribRole.text.trim(),
      rightType: _contribRightType,
      ownershipPercentage: pct,
      territoryScope: _contribTerritory.text.trim(),
    );
    setState(() {
      if (_editingContributorKey != null) {
        _contributors = [
          for (final c in _contributors)
            if (c.key == _editingContributorKey) draft else c,
        ];
      } else {
        _contributors = [..._contributors, draft];
      }
      _resetContributorEditor();
    });
  }

  void _startContributorEdit(WorkContributorDraft c) {
    setState(() {
      _editingContributorKey = c.key;
      _contribName.text = c.contributorName;
      _contribRole.text = c.contributorRole;
      _contribRightType = c.rightType == 'non_exclusive'
          ? 'non_exclusive'
          : 'exclusive';
      _contribPct.text = _formatPctForField(c.ownershipPercentage);
      _contribTerritory.text = c.territoryScope;
      _contributorError = null;
    });
  }

  String _formatPctForField(double p) {
    if ((p - p.roundToDouble()).abs() < 1e-9) {
      return '${p.round()}';
    }
    return '$p';
  }

  void _removeContributorDraft(String key) {
    setState(() {
      _contributors = _contributors.where((c) => c.key != key).toList();
      if (_editingContributorKey == key) {
        _resetContributorEditor();
      }
    });
  }

  Future<void> _syncContributors(int workId, {required bool isEdit}) async {
    final api = ref.read(worksApiProvider);
    final List<WorkContributor> original;
    if (isEdit) {
      final fresh = await api.getWork(workId);
      original = fresh.contributors;
    } else {
      original = const [];
    }
    final keptIds = _contributors
        .where((c) => c.existingId != null)
        .map((c) => c.existingId!)
        .toSet();
    for (final o in original) {
      if (!keptIds.contains(o.id)) {
        await api.deleteWorkContributor(workId, o.id);
      }
    }
    for (final d in _contributors) {
      final payload = d.toApiPayload();
      if (d.existingId != null) {
        await api.updateWorkContributor(workId, d.existingId!, payload);
      } else {
        await api.addWorkContributor(workId, payload);
      }
    }
  }

  Future<void> _save({required bool submitAfterSave}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeOfWork == 'other_work_type' &&
        _otherWorkType.text.trim().isEmpty) {
      MemberFeedback.showInfo(context, 'Describe the other work type.');
      return;
    }
    if (_targetMarket == 'other' && _targetMarketOther.text.trim().isEmpty) {
      MemberFeedback.showInfo(context, 'Describe the other target market.');
      return;
    }
    if (submitAfterSave && (!_agreementAccepted || _consentDate == null)) {
      MemberFeedback.showInfo(
        context,
        'Accept the agreement and choose a consent date.',
      );
      return;
    }
    if (submitAfterSave && !_hasCoverReadyToSubmit) {
      MemberFeedback.showInfo(
        context,
        'Cover image is required. Choose a PNG or JPG file.',
      );
      return;
    }
    if (submitAfterSave && !_ownershipWithinLimit) {
      MemberFeedback.showInfo(
        context,
        'Contributor ownership percentages cannot exceed 100% in total.',
      );
      return;
    }
    if (submitAfterSave && !_ownershipEqualsHundred) {
      MemberFeedback.showInfo(
        context,
        'Contributor ownership percentages must equal 100% before saving.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(worksApiProvider);
      int workId;
      if (widget.workId == null) {
        final created = await api.createWork(_payload());
        workId = created.id;
        await _syncContributors(workId, isEdit: false);
        await _uploadPendingFiles(workId);
      } else {
        workId = widget.workId!;
        await api.updateWork(workId, _payload());
        await _syncContributors(workId, isEdit: true);
        await _uploadPendingFiles(workId);
        ref.invalidate(workDetailProvider(workId));
      }

      if (submitAfterSave) {
        await api.submitWork(workId);
      }
      if (mounted) {
        MemberFeedback.showSuccess(
          context,
          submitAfterSave
              ? 'Work submitted successfully.'
              : 'Draft saved successfully.',
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickConsentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _consentDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _consentDate = picked);
  }

  Widget _fileCard(
    ThemeData theme, {
    required String fileType,
    required String title,
    required String subtitle,
    required bool required,
    required List<String> extensions,
    required bool allowCamera,
    String? pickedName,
    VoidCallback? onClear,
  }) {
    final headingColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    final subColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF000000);
    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_kRelatedFileButtonRadius),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: AppMemberSurfaces.inset(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: headingColor,
                      ),
                    ),
                  ),
                  if (required)
                    Text(
                      'Required',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      shape: btnShape,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _pickWorkFile(
                      fileType: fileType,
                      extensions: extensions,
                    ),
                    child: Text(
                      'Choose file',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (allowCamera) ...[
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: btnShape,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _pickWorkPhotoFromCamera(
                        fileType: fileType,
                        extensions: extensions,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Take photo',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (pickedName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: MemberBrandAppBar(
          title: widget.workId == null ? 'New work' : 'Edit work',
          showAvatar: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final langValue =
        _primaryLanguageName != null &&
            _languages.any((l) => l.name == _primaryLanguageName)
        ? _primaryLanguageName
        : (_languages.isNotEmpty ? _languages.first.name : 'English');
    final langValueResolved = langValue ?? 'English';

    return Scaffold(
      appBar: MemberBrandAppBar(
        title: widget.workId == null ? 'New work' : 'Edit work',
        showAvatar: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _sectionGap(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Type of work', theme, required: true),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _typeOfWork,
                            decoration: _fieldDec(theme, hint: 'Select type'),
                            items: [
                              for (final o in WorkFieldOptions.workTypes)
                                DropdownMenuItem(
                                  value: o.value,
                                  child: Text(o.label),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _typeOfWork = v ?? _typeOfWork),
                          ),
                        ],
                      ),
                    ),
                    if (_typeOfWork == 'other_work_type')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(
                              'Describe other type',
                              theme,
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _otherWorkType,
                              decoration: _fieldDec(
                                theme,
                                hint: 'Describe the work type',
                              ),
                              validator: (s) => (s == null || s.trim().isEmpty)
                                  ? 'Required.'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Title', theme, required: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _title,
                            decoration: _fieldDec(theme, hint: 'Work title'),
                            validator: (s) => (s == null || s.trim().isEmpty)
                                ? 'Title is required.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Subtitle', theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _subtitle,
                            decoration: _fieldDec(theme, hint: 'Optional'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            'Publication year',
                            theme,
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _year,
                            decoration: _fieldDec(theme, hint: 'YYYY'),
                            keyboardType: TextInputType.number,
                            validator: (s) {
                              final y = int.tryParse(s?.trim() ?? '');
                              if (y == null || y < 1000 || y > 9999) {
                                return 'Enter a 4-digit year.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Synopsis / description', theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _synopsis,
                            maxLines: 4,
                            decoration: _fieldDec(
                              theme,
                              hint: 'Summary of the work',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            'Primary language',
                            theme,
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: langValueResolved,
                            decoration: _fieldDec(theme, hint: 'Language'),
                            items: [
                              if (_languages.isEmpty)
                                DropdownMenuItem(
                                  value: langValueResolved,
                                  child: Text(langValueResolved),
                                )
                              else ...[
                                if (!_languages.any(
                                  (l) => l.name == langValueResolved,
                                ))
                                  DropdownMenuItem(
                                    value: langValueResolved,
                                    child: Text(langValueResolved),
                                  ),
                                for (final l in _languages)
                                  DropdownMenuItem(
                                    value: l.name,
                                    child: Text(l.name),
                                  ),
                              ],
                            ],
                            onChanged: (v) =>
                                setState(() => _primaryLanguageName = v),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Work format', theme, required: true),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _workFormat,
                            decoration: _fieldDec(theme),
                            items: [
                              for (final o in WorkFieldOptions.workFormats)
                                DropdownMenuItem(
                                  value: o.value,
                                  child: Text(o.label),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _workFormat = v ?? _workFormat),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Identifier type', theme, required: true),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _identifierType,
                            decoration: _fieldDec(theme),
                            items: [
                              for (final o in WorkFieldOptions.identifierTypes)
                                DropdownMenuItem(
                                  value: o.value,
                                  child: Text(o.label),
                                ),
                            ],
                            onChanged: (v) => setState(
                              () => _identifierType = v ?? _identifierType,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Identifier value / number', theme),
                          const SizedBox(height: 6),
                          Text(
                            'Optional. If you enter one, it must not already be registered '
                            'for another work with the same identifier type.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _identifierValue,
                            decoration: _fieldDec(
                              theme,
                              hint: 'ISBN, ISSN, URL, etc.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('DOI', theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _doi,
                            decoration: _fieldDec(theme, hint: 'Optional'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Publisher name', theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _publisherName,
                            decoration: _fieldDec(theme, hint: 'Optional'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            'Target market for the work',
                            theme,
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _targetMarket,
                            decoration: _fieldDec(theme),
                            items: [
                              for (final o in WorkFieldOptions.targetMarkets)
                                DropdownMenuItem(
                                  value: o.value,
                                  child: Text(o.label),
                                ),
                            ],
                            onChanged: (v) => setState(
                              () => _targetMarket = v ?? _targetMarket,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_targetMarket == 'other')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(
                              'Other target market',
                              theme,
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _targetMarketOther,
                              decoration: _fieldDec(theme),
                              validator: (s) => (s == null || s.trim().isEmpty)
                                  ? 'Required for “other”.'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(
                            'Production status',
                            theme,
                            required: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Work no longer produced in print or electronic version for sale.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'yes',
                                label: Text('Produced'),
                              ),
                              ButtonSegment(
                                value: 'no',
                                label: Text('Not produced'),
                              ),
                            ],
                            selected: {_productionStatus},
                            onSelectionChanged: (s) =>
                                setState(() => _productionStatus = s.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contributors',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.onSurface
                            : const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add everyone with a stake in this work. Combined ownership must '
                      'total 100% before you can save.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.onSurface
                            : const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Total ownership: ${_contributorTotalOwnership.toStringAsFixed(2)}%',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_contributors.isNotEmpty &&
                            _ownershipEqualsHundred) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (!_ownershipWithinLimit) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: theme.colorScheme.error),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ownership total exceeds 100%. Reduce percentages so '
                                  'the combined ownership stays within 100%.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_contributors.isNotEmpty &&
                        _ownershipWithinLimit &&
                        !_ownershipEqualsHundred) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFFC5CCD6)
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.45,
                                  ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Contributors are listed, but percentages must add up '
                                  'to exactly 100% before you can save.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    for (final c in _contributors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DecoratedBox(
                          decoration: AppMemberSurfaces.inset(theme),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.contributorName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${c.contributorRole} · ${c.rightType} · '
                                        '${c.ownershipPercentage}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      if (c.territoryScope
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          c.territoryScope.trim(),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _startContributorEdit(c),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _removeContributorDraft(c.key),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_contributors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'No contributors yet. Use the form below to add each person.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(
                              'Contributor name',
                              theme,
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contribName,
                              decoration: _fieldDec(theme),
                              onChanged: (_) =>
                                  setState(() => _contributorError = null),
                            ),
                          ],
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(
                              'Contributor role',
                              theme,
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contribRole,
                              decoration: _fieldDec(theme),
                              onChanged: (_) =>
                                  setState(() => _contributorError = null),
                            ),
                          ],
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Right type', theme, required: true),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _contribRightType,
                              decoration: _fieldDec(theme),
                              items: const [
                                DropdownMenuItem(
                                  value: 'exclusive',
                                  child: Text('Exclusive'),
                                ),
                                DropdownMenuItem(
                                  value: 'non_exclusive',
                                  child: Text('Non-exclusive'),
                                ),
                              ],
                              onChanged: (v) => setState(() {
                                _contribRightType = v ?? 'exclusive';
                                _contributorError = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel(
                              'Ownership percentage',
                              theme,
                              required: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contribPct,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _fieldDec(
                                theme,
                                hint: 'e.g. 50 or 33.33',
                              ),
                              onChanged: (_) =>
                                  setState(() => _contributorError = null),
                            ),
                          ],
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Territory scope', theme),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contribTerritory,
                              decoration: _fieldDec(theme, hint: 'Optional'),
                              onChanged: (_) =>
                                  setState(() => _contributorError = null),
                            ),
                          ],
                        ),
                      ),
                    if (!_hideContributorFormWhenComplete &&
                        _contributorError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _contributorError!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    if (!_hideContributorFormWhenComplete)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonal(
                            onPressed: _upsertContributorDraft,
                            child: Text(
                              _editingContributorKey != null
                                  ? 'Update contributor'
                                  : 'Add contributor',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_editingContributorKey != null)
                            OutlinedButton(
                              onPressed: () =>
                                  setState(_resetContributorEditor),
                              child: const Text('Cancel edit'),
                            ),
                        ],
                      ),
                    if (_hideContributorFormWhenComplete) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Contributor ownership has reached 100%. Edit or remove existing contributors to make changes.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_showRelatedFilesSection) ...[
              DecoratedBox(
                decoration: AppMemberSurfaces.section(theme),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Related files',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onSurface
                              : const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isNew
                            ? 'Cover image is required before submitting (PNG or JPEG only). Copyright page and proof of ownership are optional and can be PDF, PNG, or JPEG.'
                            : 'Cover is required before submitting; uploads already saved with this work appear below by filename. Optional files behave the same as for new works. Choose a file to attach or refresh an attachment before saving.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onSurface
                              : const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fileCard(
                        theme,
                        fileType: 'cover_image',
                        title: 'Cover image',
                        subtitle: 'Front cover of the work (PNG or JPEG only).',
                        required: true,
                        extensions: const ['png', 'jpg', 'jpeg'],
                        allowCamera: _allowsCameraForExtensions(const [
                          'png',
                          'jpg',
                          'jpeg',
                        ]),
                        pickedName: _pendingOrAttachedName(
                          pendingBytes: _coverBytes,
                          pendingName: _coverName,
                          fileType: 'cover_image',
                        ),
                        onClear: _coverBytes != null
                            ? () => setState(() {
                                _coverBytes = null;
                                _coverName = null;
                              })
                            : null,
                      ),
                      _fileCard(
                        theme,
                        fileType: 'copyright_page',
                        title: 'Copyright page',
                        subtitle:
                            'Copyright notice page if available (PDF, PNG, or JPEG).',
                        required: false,
                        extensions: const ['pdf', 'png', 'jpg', 'jpeg'],
                        allowCamera: _allowsCameraForExtensions(const [
                          'pdf',
                          'png',
                          'jpg',
                          'jpeg',
                        ]),
                        pickedName: _pendingOrAttachedName(
                          pendingBytes: _copyrightBytes,
                          pendingName: _copyrightName,
                          fileType: 'copyright_page',
                        ),
                        onClear: _copyrightBytes != null
                            ? () => setState(() {
                                _copyrightBytes = null;
                                _copyrightName = null;
                              })
                            : null,
                      ),
                      _fileCard(
                        theme,
                        fileType: 'proof_of_ownership',
                        title: 'Proof of ownership',
                        subtitle: 'Supporting document (PDF, PNG, or JPEG).',
                        required: false,
                        extensions: const ['pdf', 'png', 'jpg', 'jpeg'],
                        allowCamera: _allowsCameraForExtensions(const [
                          'pdf',
                          'png',
                          'jpg',
                          'jpeg',
                        ]),
                        pickedName: _pendingOrAttachedName(
                          pendingBytes: _proofBytes,
                          pendingName: _proofName,
                          fileType: 'proof_of_ownership',
                        ),
                        onClear: _proofBytes != null
                            ? () => setState(() {
                                _proofBytes = null;
                                _proofName = null;
                              })
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Notes / additional information', theme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: _fieldDec(theme, hint: 'Optional'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: AppMemberSurfaces.section(theme),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rightsholder affiliation agreement',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Between REPRONIG and you (the Rightsholder). Read the terms, consent, and confirm the date.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: AppMemberSurfaces.inset(theme),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Agreement '),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                    const TextSpan(text: '\n'),
                                    TextSpan(
                                      text:
                                          WorkConsentCopy.agreementCheckboxLead,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              value: _agreementAccepted,
                              onChanged: (v) => setState(
                                () => _agreementAccepted = v ?? false,
                              ),
                            ),
                            TextButton(
                              onPressed: _showFullTerms,
                              child: const Text(
                                'View full terms and conditions',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              WorkConsentCopy.paragraph1,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              WorkConsentCopy.paragraph2,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('Consent date', theme, required: true),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                side: BorderSide(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFFC5CCD6)
                                      : theme.colorScheme.outline.withValues(
                                          alpha: 0.45,
                                        ),
                                ),
                              ),
                              title: Text(
                                _consentDate == null
                                    ? 'Choose date'
                                    : DateFormat.yMMMd().format(_consentDate!),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: _pickConsentDate,
                                child: const Text('Choose'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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
                  onPressed: _saving
                      ? null
                      : () => _save(submitAfterSave: false),
                  child: Text(
                    'Save draft',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
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
                  onPressed: _saving
                      ? null
                      : () => _save(submitAfterSave: true),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Submit work',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
