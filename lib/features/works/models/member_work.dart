import 'work_contributor.dart';

/// Attachment row from API `works/{id}` `files`.
class UploadedWorkFile {
  const UploadedWorkFile({
    required this.fileType,
    required this.fileName,
    this.fileUrl,
  });

  final String fileType;
  final String fileName;
  final String? fileUrl;

  bool get isImage {
    final n = (fileName).toLowerCase();
    final u = (fileUrl ?? '').toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.jpg') ||
        u.endsWith('.jpeg');
  }

  factory UploadedWorkFile.fromJson(Map<String, dynamic> json) {
    return UploadedWorkFile(
      fileType: (json['file_type'] as String?)?.trim() ?? '',
      fileName: (json['file_name'] as String?)?.trim() ?? '',
      fileUrl: _stringify(
        json['file_url'] ??
            json['url'] ??
            json['download_url'] ??
            json['path'] ??
            json['file_path'],
      ),
    );
  }
}

/// Member `WorkResource` (list + detail + editor).
class MemberWork {
  const MemberWork({
    required this.id,
    required this.title,
    this.subtitle,
    this.typeOfWork,
    this.workStatus,
    this.verificationStatus,
    this.updateRequestStatus,
    this.updateRequestStatusLabel,
    this.referenceNumber,
    this.submittedAt,
    this.publicationYear,
    this.synopsis,
    this.primaryLanguage,
    this.workFormat,
    this.identifierType,
    this.identifierValue,
    this.doi,
    this.publisherName,
    this.targetMarket,
    this.targetMarketOther,
    this.productionStatus,
    this.agreementAccepted = false,
    this.dateOfConsent,
    this.otherWorkType,
    this.notes,
    this.isRestricted = false,
    this.contributors = const [],
    this.contributorsCount = 0,
    this.filesCount = 0,
    this.attachedFiles = const [],
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? typeOfWork;
  final String? workStatus;
  final String? verificationStatus;
  final String? updateRequestStatus;
  final String? updateRequestStatusLabel;
  final String? referenceNumber;
  final String? submittedAt;
  final int? publicationYear;
  final String? synopsis;
  final String? primaryLanguage;
  final String? workFormat;
  final String? identifierType;
  final String? identifierValue;
  final String? doi;
  final String? publisherName;
  final String? targetMarket;
  final String? targetMarketOther;
  final String? productionStatus;
  final bool agreementAccepted;
  final String? dateOfConsent;
  final String? otherWorkType;
  final String? notes;
  final bool isRestricted;
  final List<WorkContributor> contributors;
  final int contributorsCount;
  final int filesCount;
  final List<UploadedWorkFile> attachedFiles;

  UploadedWorkFile? get coverImageFile {
    for (final f in attachedFiles) {
      if (f.fileType == 'cover_image') return f;
    }
    return null;
  }

  String? get coverImageUrl {
    final cover = coverImageFile;
    if (cover == null || !cover.isImage) return null;
    final u = cover.fileUrl?.trim();
    if (u == null || u.isEmpty) return null;
    return u;
  }

  bool get isDraft => workStatus == 'draft';

  bool get canEdit =>
      !isRestricted &&
      (workStatus == 'draft' ||
          workStatus == 'changes_requested' ||
          (workStatus == 'approved' && updateRequestStatus == 'approved'));

  factory MemberWork.fromJson(Map<String, dynamic> json) {
    final contributorsRaw = json['contributors'];
    final contributorsList = contributorsRaw is List<dynamic>
        ? contributorsRaw
            .map(
              (e) => WorkContributor.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList()
        : const <WorkContributor>[];
    final filesRaw = json['files'];
    final attached = _attachedFilesFromJson(filesRaw);
    return MemberWork(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled work',
      subtitle: json['subtitle'] as String?,
      typeOfWork: json['type_of_work'] as String?,
      workStatus: json['work_status'] as String?,
      verificationStatus: json['verification_status'] as String?,
      updateRequestStatus: json['update_request_status'] as String?,
      updateRequestStatusLabel: json['update_request_status_label'] as String?,
      referenceNumber: json['reference_number'] as String?,
      submittedAt: _stringify(json['submitted_at']),
      publicationYear: _intOrNull(json['publication_year']),
      synopsis: json['synopsis'] as String?,
      primaryLanguage: json['primary_language'] as String?,
      workFormat: json['work_format'] as String?,
      identifierType: json['identifier_type'] as String?,
      identifierValue: json['identifier_value'] as String?,
      doi: json['doi'] as String?,
      publisherName: json['publisher_name'] as String?,
      targetMarket: json['target_market'] as String?,
      targetMarketOther: json['target_market_other'] as String?,
      productionStatus: json['production_status'] as String?,
      agreementAccepted: json['agreement_accepted'] == true,
      dateOfConsent: json['date_of_consent'] as String?,
      otherWorkType: json['other_work_type'] as String?,
      notes: json['notes'] as String?,
      isRestricted: json['is_restricted'] == true,
      contributors: contributorsList,
      contributorsCount: contributorsList.length,
      filesCount: attached.length,
      attachedFiles: attached,
    );
  }

  Map<String, dynamic> toCreateOrUpdateBody() {
    return <String, dynamic>{
      'type_of_work': typeOfWork,
      'title': title,
      'subtitle': subtitle,
      if (publicationYear != null) 'publication_year': publicationYear,
      'synopsis': synopsis,
      'primary_language': primaryLanguage,
      'work_format': workFormat,
      'identifier_type': identifierType,
      'identifier_value': identifierValue,
      'doi': doi,
      'publisher_name': publisherName,
      'target_market': targetMarket,
      'target_market_other': targetMarketOther,
      'production_status': productionStatus,
      'agreement_accepted': agreementAccepted,
      'date_of_consent': dateOfConsent,
      'other_work_type': otherWorkType,
      'notes': notes,
    };
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaginatedWorksResult {
  const PaginatedWorksResult({
    required this.items,
    required this.meta,
  });

  final List<MemberWork> items;
  final PaginationMeta meta;
}

class LanguageOption {
  const LanguageOption({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory LanguageOption.fromJson(Map<String, dynamic> json) {
    return LanguageOption(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }
}

List<UploadedWorkFile> _attachedFilesFromJson(Object? raw) {
  if (raw is! List<dynamic>) return const [];
  final out = <UploadedWorkFile>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(UploadedWorkFile.fromJson(e));
    } else if (e is Map) {
      out.add(UploadedWorkFile.fromJson(Map<String, dynamic>.from(e)));
    }
  }
  return out;
}

String? _stringify(Object? v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

int? _intOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}
