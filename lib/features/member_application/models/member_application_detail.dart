import '../../auth/models/public_association.dart';

class MemberApplicationDocumentRow {
  const MemberApplicationDocumentRow({
    required this.id,
    required this.documentType,
    this.fileName,
    this.fileUrl,
  });

  final int id;
  final String documentType;
  final String? fileName;
  final String? fileUrl;

  factory MemberApplicationDocumentRow.fromJson(Map<String, dynamic> json) {
    return MemberApplicationDocumentRow(
      id: (json['id'] as num).toInt(),
      documentType: json['document_type'] as String? ?? '',
      fileName: json['file_name'] as String?,
      fileUrl: json['file_url'] as String? ?? json['download_url'] as String?,
    );
  }
}

/// Parsed `MemberApplicationResource` from `member-applications/*`.
class MemberApplicationDetail {
  const MemberApplicationDetail({
    required this.id,
    this.applicationReference,
    this.userFirstName,
    this.userLastName,
    required this.applicationStatus,
    this.affiliationStatus,
    this.submissionStage,
    this.association,
    required this.applicantType,
    this.memberAuthorType,
    this.memberAuthorCategory,
    this.nationality,
    this.countryOfResidence,
    required this.isDiaspora,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountOwnerName,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.publisherOrganisationName,
    this.publisherTin,
    this.publisherLocationAddress,
    this.publisherPostalAddress,
    this.publisherEmail,
    this.publisherPhone,
    required this.consentAccepted,
    this.consentDate,
    this.notes,
    this.affiliationReviewNote,
    this.memberProvidedId,
    required this.documents,
    this.submittedAt,
    this.reviewedAt,
  });

  final int id;
  final String? applicationReference;
  final String? userFirstName;
  final String? userLastName;
  final String applicationStatus;
  final String? affiliationStatus;
  final String? submissionStage;
  final PublicAssociation? association;
  final String applicantType;
  final String? memberAuthorType;
  final String? memberAuthorCategory;
  final String? nationality;
  final String? countryOfResidence;
  final bool isDiaspora;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountOwnerName;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? publisherOrganisationName;
  final String? publisherTin;
  final String? publisherLocationAddress;
  final String? publisherPostalAddress;
  final String? publisherEmail;
  final String? publisherPhone;
  final bool consentAccepted;
  final String? consentDate;
  final String? notes;
  final String? affiliationReviewNote;
  final String? memberProvidedId;
  final List<MemberApplicationDocumentRow> documents;
  final String? submittedAt;
  final String? reviewedAt;

  bool get canEdit =>
      applicationStatus == 'draft' ||
      applicationStatus == 'changes_requested';

  bool get hasProofOfId =>
      documents.any((d) => d.documentType == 'proof_of_id');

  bool get hasProofOfAddress =>
      documents.any((d) => d.documentType == 'proof_of_address');

  bool get canSubmit =>
      canEdit &&
      hasProofOfId &&
      hasProofOfAddress &&
      consentAccepted &&
      (consentDate != null && consentDate!.trim().isNotEmpty);

  bool get isAuthorPath => applicantType == 'author';

  bool get isPublisherPath =>
      applicantType == 'publisher' ||
      applicantType == 'corporate_publisher';

  factory MemberApplicationDetail.fromJson(Map<String, dynamic> json) {
    final assoc = json['association'];
    PublicAssociation? association;
    if (assoc is Map<String, dynamic>) {
      association = PublicAssociation.fromJson(assoc);
    }

    final docsRaw = json['documents'];
    final docs = <MemberApplicationDocumentRow>[];
    if (docsRaw is List<dynamic>) {
      for (final e in docsRaw) {
        if (e is Map<String, dynamic>) {
          docs.add(MemberApplicationDocumentRow.fromJson(e));
        }
      }
    }

    String? uFirst;
    String? uLast;
    final userMap = json['user'];
    if (userMap is Map<String, dynamic>) {
      uFirst = userMap['first_name'] as String?;
      uLast = userMap['last_name'] as String?;
    }

    return MemberApplicationDetail(
      id: (json['id'] as num).toInt(),
      applicationReference: json['application_reference'] as String?,
      userFirstName: uFirst,
      userLastName: uLast,
      applicationStatus: json['application_status'] as String? ?? 'draft',
      affiliationStatus: json['affiliation_status'] as String?,
      submissionStage: json['submission_stage'] as String?,
      association: association,
      applicantType: json['applicant_type'] as String? ?? 'author',
      memberAuthorType: json['member_author_type'] as String?,
      memberAuthorCategory: json['member_author_category'] as String?,
      nationality: json['nationality'] as String?,
      countryOfResidence: json['country_of_residence'] as String?,
      isDiaspora: json['is_diaspora'] == true,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountOwnerName: json['bank_account_owner_name'] as String?,
      nextOfKinName: json['next_of_kin_name'] as String?,
      nextOfKinPhone: json['next_of_kin_phone'] as String?,
      publisherOrganisationName: json['publisher_organisation_name'] as String?,
      publisherTin: json['publisher_tin'] as String?,
      publisherLocationAddress: json['publisher_location_address'] as String?,
      publisherPostalAddress: json['publisher_postal_address'] as String?,
      publisherEmail: json['publisher_email'] as String?,
      publisherPhone: json['publisher_phone'] as String?,
      consentAccepted: json['consent_accepted'] == true,
      consentDate: json['consent_date'] as String?,
      notes: json['notes'] as String?,
      affiliationReviewNote: json['affiliation_review_note'] as String?,
      memberProvidedId: json['member_provided_id'] as String?,
      documents: docs,
      submittedAt: json['submitted_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }
}
