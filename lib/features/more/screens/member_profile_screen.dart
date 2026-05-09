import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../../widgets/member_form_fields.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../../dashboard/providers/member_dashboard_provider.dart';
import '../data/more_api.dart';
import '../models/member_profile_detail.dart';
import '../providers/more_providers.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key});

  static const routeName = 'member-more-profile';

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _occupation = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  final _postal = TextEditingController();
  final _publisherName = TextEditingController();
  final _corporateName = TextEditingController();
  final _memberProvidedId = TextEditingController();

  DateTime? _dateOfBirth;
  var _loading = true;
  var _saving = false;
  var _uploadingAvatar = false;
  MemberProfileDetail? _loaded;
  List<LocationOption> _states = const [];
  List<LocationOption> _cities = const [];
  String? _selectedStateId;
  String? _selectedCityId;
  bool _loadingLocations = false;

  LocationOption? _findByName(List<LocationOption> options, String name) {
    for (final option in options) {
      if (option.name.toLowerCase() == name.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  LocationOption? _findById(List<LocationOption> options, String? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _occupation.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _postal.dispose();
    _publisherName.dispose();
    _corporateName.dispose();
    _memberProvidedId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(moreApiProvider);
      final p = await api.fetchMemberProfile();
      final states = await api.listStates();
      if (!mounted) return;
      setState(() {
        _loaded = p;
        _states = states;
        if (p != null) {
          _firstName.text = p.firstName;
          _lastName.text = p.lastName;
          _occupation.text = p.occupation ?? '';
          _address1.text = p.addressLine1 ?? '';
          _address2.text = p.addressLine2 ?? '';
          _city.text = p.city ?? '';
          _state.text = p.state ?? '';
          _country.text = (p.country ?? '').trim().isEmpty
              ? 'Nigeria'
              : p.country!;
          _postal.text = p.postalCode ?? '';
          _publisherName.text = p.publisherName ?? '';
          _corporateName.text = p.corporateName ?? '';
          _memberProvidedId.text = p.memberProvidedId ?? '';
          if (p.dateOfBirth != null && p.dateOfBirth!.isNotEmpty) {
            try {
              _dateOfBirth = DateTime.parse(p.dateOfBirth!);
            } on FormatException {
              _dateOfBirth = null;
            }
          } else {
            _dateOfBirth = null;
          }
        }
        if (_country.text.trim().isEmpty) {
          _country.text = 'Nigeria';
        }
      });
      await _syncStateAndCityLookups();
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncStateAndCityLookups() async {
    final stateName = _state.text.trim().toLowerCase();
    final selectedState = _findByName(_states, stateName);
    if (selectedState == null) {
      setState(() {
        _selectedStateId = null;
        _cities = const [];
        _selectedCityId = null;
      });
      return;
    }
    _selectedStateId = selectedState.id;
    await _loadCitiesForState(
      selectedState.id,
      prefillCityName: _city.text.trim(),
    );
  }

  Future<void> _loadCitiesForState(
    String stateId, {
    String? prefillCityName,
  }) async {
    setState(() => _loadingLocations = true);
    try {
      final cities = await ref
          .read(moreApiProvider)
          .listCitiesForState(stateId);
      if (!mounted) return;
      final cityName = (prefillCityName ?? '').toLowerCase();
      final selectedCity = _findByName(cities, cityName);
      setState(() {
        _cities = cities;
        _selectedCityId = selectedCity?.id;
      });
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  Map<String, dynamic> _payload() {
    String? dobStr;
    if (_dateOfBirth != null) {
      final d = _dateOfBirth!;
      dobStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    String? nz(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? null : t;
    }

    return <String, dynamic>{
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'date_of_birth': dobStr,
      'occupation': nz(_occupation.text),
      'residential_address_line_1': nz(_address1.text),
      'residential_address_line_2': nz(_address2.text),
      'city': nz(_city.text),
      'state': nz(_state.text),
      'country': nz(_country.text),
      'postal_code': nz(_postal.text),
      'publisher_name': nz(_publisherName.text),
      'corporate_name': nz(_corporateName.text),
      'member_provided_id': nz(_memberProvidedId.text),
    };
  }

  Future<void> _save() async {
    if (_loaded == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(moreApiProvider).updateMemberProfile(_payload());
      ref.invalidate(memberDashboardSummaryProvider);
      await ref.read(authSessionProvider.notifier).refreshFromServer();
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Profile updated.');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      await ref
          .read(moreApiProvider)
          .uploadAvatar(
            filePath: file.path,
            fileName: file.path.split('/').last,
          );
      ref.invalidate(memberDashboardSummaryProvider);
      await ref.read(authSessionProvider.notifier).refreshFromServer();
      if (mounted) {
        MemberFeedback.showSuccess(context, 'Profile picture updated.');
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openAvatarPickerSheet() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Use camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await _pickAvatar(choice);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Widget _pill(ThemeData theme, String text, {Color? bg, Color? fg}) {
    final background = bg ?? theme.colorScheme.surfaceContainerHighest;
    final foreground = fg ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _textField(
    ThemeData theme,
    String label,
    TextEditingController c, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MemberFormFieldLabel(text: label),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            decoration: memberFormInputDecoration(theme, hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: AppMemberSurfaces.section(theme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sectionPanel(ThemeData theme, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: AppMemberSurfaces.section(theme),
        child: child,
      ),
    );
  }

  Widget _emptyStatePanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DecoratedBox(
        decoration: AppMemberSurfaces.section(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No approved member profile is available yet. Complete onboarding first.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).user?.user;
    final avatarUrl = user?.avatarUrl?.trim();
    final initialsSource = (user?.firstName ?? user?.name ?? 'M').trim();
    final initials = initialsSource.isEmpty
        ? 'M'
        : initialsSource[0].toUpperCase();

    return Scaffold(
      appBar: const MemberBrandAppBar(
        title: 'Member profile',
        showAvatar: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loaded == null
          ? Center(child: _emptyStatePanel(theme))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _sectionPanel(
                    theme,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child:
                                          avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  _avatarInitials(
                                                    theme,
                                                    initials,
                                                  ),
                                            )
                                          : _avatarInitials(theme, initials),
                                    ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.surface,
                                          width: 1.6,
                                        ),
                                      ),
                                      child: IconButton(
                                        tooltip: 'Edit profile picture',
                                        onPressed: _uploadingAvatar
                                            ? null
                                            : _openAvatarPickerSheet,
                                        icon: _uploadingAvatar
                                            ? SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: theme
                                                          .colorScheme
                                                          .onPrimary,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.edit_rounded,
                                                size: 18,
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(
                                          minHeight: 30,
                                          minWidth: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile picture',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Select an image to update your profile picture.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your membership',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_loaded!.memberCode != null)
                                _pill(theme, 'Code ${_loaded!.memberCode}'),
                              if (_loaded!.approvalStatus != null)
                                _pill(
                                  theme,
                                  _loaded!.approvalStatus!.replaceAll('_', ' '),
                                  bg: AppColors.primary.withValues(alpha: 0.12),
                                  fg: AppColors.primary,
                                ),
                            ],
                          ),
                          if (_loaded!.associationName != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Society',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _loaded!.associationName!,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_loaded!.email.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SelectableText(
                                    _loaded!.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _section(
                    context,
                    title: 'Name',
                    icon: Icons.badge_outlined,
                    children: [
                      _textField(theme, 'First name', _firstName),
                      _textField(theme, 'Last name', _lastName),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    context,
                    title: 'Profile',
                    icon: Icons.person_outline_rounded,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MemberFormFieldLabel(text: 'Date of birth'),
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppFormInput.borderRadius,
                                ),
                                border: Border.all(
                                  color: AppFormInput.outlineColor,
                                  width: AppFormInput.borderWidth,
                                ),
                                color: theme.colorScheme.surface,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dateOfBirth == null
                                            ? 'Not set'
                                            : DateFormat.yMMMd().format(
                                                _dateOfBirth!,
                                              ),
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _pickDob,
                                      child: const Text('Choose'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _textField(
                        theme,
                        'Occupation',
                        _occupation,
                        hint: 'Optional',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    context,
                    title: 'Address',
                    icon: Icons.home_outlined,
                    children: [
                      _textField(theme, 'Address line 1', _address1),
                      _textField(
                        theme,
                        'Address line 2',
                        _address2,
                        hint: 'Optional',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MemberFormFieldLabel(text: 'State / region'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStateId,
                              isExpanded: true,
                              decoration: memberFormInputDecoration(
                                theme,
                                hint: 'Select state',
                              ),
                              items: _states
                                  .map(
                                    (state) => DropdownMenuItem<String>(
                                      value: state.id,
                                      child: Text(state.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) async {
                                setState(() {
                                  _selectedStateId = value;
                                  final selected = _findById(_states, value);
                                  _state.text = selected?.name ?? '';
                                  _selectedCityId = null;
                                  _city.clear();
                                  _cities = const [];
                                });
                                if (value != null) {
                                  await _loadCitiesForState(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MemberFormFieldLabel(text: 'City'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCityId,
                              isExpanded: true,
                              decoration: memberFormInputDecoration(
                                theme,
                                hint: _selectedStateId == null
                                    ? 'Select state first'
                                    : 'Select city',
                              ),
                              items: _cities
                                  .map(
                                    (city) => DropdownMenuItem<String>(
                                      value: city.id,
                                      child: Text(city.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  _selectedStateId == null || _loadingLocations
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedCityId = value;
                                        final selected = _findById(
                                          _cities,
                                          value,
                                        );
                                        _city.text = selected?.name ?? '';
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      _textField(theme, 'Country', _country),
                      _textField(theme, 'Postal code', _postal),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _section(
                    context,
                    title: 'Publishing',
                    icon: Icons.menu_book_outlined,
                    children: [
                      _textField(
                        theme,
                        'Publisher name',
                        _publisherName,
                        hint: 'Optional',
                      ),
                      _textField(
                        theme,
                        'Corporate name',
                        _corporateName,
                        hint: 'Optional',
                      ),
                      _textField(
                        theme,
                        'Member-provided ID',
                        _memberProvidedId,
                        hint: 'Optional',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _avatarInitials(ThemeData theme, String initials) {
    return Container(
      width: 72,
      height: 72,
      color: theme.brightness == Brightness.dark
          ? AppColors.darkMuted
          : AppColors.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : AppColors.primary,
        ),
      ),
    );
  }
}
