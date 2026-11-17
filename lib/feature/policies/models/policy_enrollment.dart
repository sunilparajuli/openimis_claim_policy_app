import 'package:openimis_claim_policy_app/core/utils/insuree_number.dart';

enum PolicyApplication { csu, hiv }

/// Marker used by the CSU HIV Android application and backend rules to
/// distinguish HIV enrolments from general CSU beneficiaries.
const hivInsureeMarkerEmail = 'newhivuser_XM7dw70J0M3N@gmail.com';

class PolicyInsureeDraft {
  const PolicyInsureeDraft({
    required this.chfId,
    required this.lastName,
    required this.otherNames,
    required this.genderId,
    required this.dateOfBirth,
    this.uuid,
    this.familyId,
    this.isHead = false,
    this.identificationNumber,
    this.identificationTypeId,
    this.maritalStatus,
    this.phone,
    this.email,
    this.cardIssued = false,
    this.relationshipId,
    this.professionId,
    this.educationId,
    this.healthFacilityId,
    this.currentAddress,
    this.currentVillageId,
    this.geolocation,
    this.photoFilename,
    this.photoBase64,
  });

  final String chfId;
  final String lastName;
  final String otherNames;
  final String genderId;
  final DateTime dateOfBirth;
  final String? uuid;
  final int? familyId;
  final bool isHead;
  final String? identificationNumber;
  final String? identificationTypeId;
  final String? maritalStatus;
  final String? phone;
  final String? email;
  final bool cardIssued;
  final int? relationshipId;
  final int? professionId;
  final int? educationId;
  final int? healthFacilityId;
  final String? currentAddress;
  final int? currentVillageId;
  final String? geolocation;
  final String? photoFilename;
  final String? photoBase64;

  PolicyInsureeDraft withDemographics({
    required String genderId,
    required DateTime dateOfBirth,
  }) => PolicyInsureeDraft(
    chfId: chfId,
    lastName: lastName,
    otherNames: otherNames,
    genderId: genderId,
    dateOfBirth: dateOfBirth,
    uuid: uuid,
    familyId: familyId,
    isHead: isHead,
    identificationNumber: identificationNumber,
    identificationTypeId: identificationTypeId,
    maritalStatus: maritalStatus,
    phone: phone,
    email: email,
    cardIssued: cardIssued,
    relationshipId: relationshipId,
    professionId: professionId,
    educationId: educationId,
    healthFacilityId: healthFacilityId,
    currentAddress: currentAddress,
    currentVillageId: currentVillageId,
    geolocation: geolocation,
    photoFilename: photoFilename,
    photoBase64: photoBase64,
  );

  Map<String, dynamic> toJson() => {
    'chfId': chfId,
    'lastName': lastName,
    'otherNames': otherNames,
    'genderId': genderId,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'uuid': uuid,
    'familyId': familyId,
    'isHead': isHead,
    'identificationNumber': identificationNumber,
    'identificationTypeId': identificationTypeId,
    'maritalStatus': maritalStatus,
    'phone': phone,
    'email': email,
    'cardIssued': cardIssued,
    'relationshipId': relationshipId,
    'professionId': professionId,
    'educationId': educationId,
    'healthFacilityId': healthFacilityId,
    'currentAddress': currentAddress,
    'currentVillageId': currentVillageId,
    'geolocation': geolocation,
    'photoFilename': photoFilename,
    'photoBase64': photoBase64,
  };

  factory PolicyInsureeDraft.fromJson(Map<String, dynamic> json) =>
      PolicyInsureeDraft(
        chfId: json['chfId']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        otherNames: json['otherNames']?.toString() ?? '',
        genderId: json['genderId']?.toString() ?? '',
        dateOfBirth: DateTime.parse(json['dateOfBirth'].toString()),
        uuid: json['uuid']?.toString(),
        familyId: _int(json['familyId']),
        isHead: json['isHead'] == true,
        identificationNumber: json['identificationNumber']?.toString(),
        identificationTypeId: json['identificationTypeId']?.toString(),
        maritalStatus: json['maritalStatus']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        cardIssued: json['cardIssued'] == true,
        relationshipId: _int(json['relationshipId']),
        professionId: _int(json['professionId']),
        educationId: _int(json['educationId']),
        healthFacilityId: _int(json['healthFacilityId']),
        currentAddress: json['currentAddress']?.toString(),
        currentVillageId: _int(json['currentVillageId']),
        geolocation: json['geolocation']?.toString(),
        photoFilename: json['photoFilename']?.toString(),
        photoBase64: json['photoBase64']?.toString(),
      );

  String validatedChfId(PolicyApplication application) {
    final normalized = InsureeNumber.normalize(chfId);
    final issue = InsureeNumber.validate(normalized);
    if (issue != null) {
      throw const FormatException('A valid MPI/CHFID is required.');
    }
    if (application == PolicyApplication.hiv &&
        RegExp(r'^\d+$').hasMatch(normalized)) {
      throw const FormatException(
        'mutation.insuree.mpi_entirely_numeric_error',
      );
    }
    return normalized;
  }

  Map<String, dynamic> toGraphQLInput(
    PolicyApplication application, {
    int? resolvedFamilyId,
    bool forFamilyHead = false,
  }) {
    final result = <String, dynamic>{
      'chfId': validatedChfId(application),
      'lastName': lastName.trim(),
      'otherNames': otherNames.trim(),
      'genderId': genderId,
      'dob': _date(dateOfBirth),
      if (_present(uuid)) 'uuid': uuid,
      if (!forFamilyHead) 'familyId': resolvedFamilyId ?? familyId,
      if (!forFamilyHead) 'head': isHead,
      if (_present(identificationNumber)) 'passport': identificationNumber,
      if (_present(identificationTypeId)) 'typeOfIdId': identificationTypeId,
      if (_present(maritalStatus)) 'marital': maritalStatus,
      if (_present(phone)) 'phone': phone!.trim(),
      if (_present(currentAddress)) 'currentAddress': currentAddress!.trim(),
      if (currentVillageId != null) 'currentVillageId': currentVillageId,
      if (relationshipId != null) 'relationshipId': relationshipId,
      if (professionId != null) 'professionId': professionId,
      if (educationId != null) 'educationId': educationId,
      if (healthFacilityId != null) 'healthFacilityId': healthFacilityId,
      if (_present(geolocation)) 'geolocation': geolocation,
      'cardIssued': application == PolicyApplication.hiv ? false : cardIssued,
      if (application == PolicyApplication.hiv)
        'email': hivInsureeMarkerEmail
      else if (_present(email))
        'email': email!.trim(),
      if (_present(photoFilename) || _present(photoBase64))
        'photo': {
          if (_present(photoFilename)) 'filename': photoFilename,
          if (_present(photoBase64)) 'photo': photoBase64,
        },
    };
    result.removeWhere((_, value) => value == null);
    return result;
  }
}

class PolicyFamilyDraft {
  const PolicyFamilyDraft({
    required this.application,
    required this.locationId,
    required this.head,
    this.poverty = false,
    this.familyTypeId,
    this.address,
    this.ethnicity,
    this.confirmationNumber,
    this.confirmationTypeId,
    this.isOffline = true,
  });

  final PolicyApplication application;
  final int locationId;
  final PolicyInsureeDraft head;
  final bool poverty;
  final String? familyTypeId;
  final String? address;
  final String? ethnicity;
  final String? confirmationNumber;
  final String? confirmationTypeId;
  final bool isOffline;

  Map<String, dynamic> toJson() => {
    'application': application.name,
    'locationId': locationId,
    'head': head.toJson(),
    'poverty': poverty,
    'familyTypeId': familyTypeId,
    'address': address,
    'ethnicity': ethnicity,
    'confirmationNumber': confirmationNumber,
    'confirmationTypeId': confirmationTypeId,
    'isOffline': isOffline,
  };

  factory PolicyFamilyDraft.fromJson(Map<String, dynamic> json) =>
      PolicyFamilyDraft(
        application: PolicyApplication.values.firstWhere(
          (value) => value.name == json['application'],
          orElse: () => PolicyApplication.csu,
        ),
        locationId: _int(json['locationId']) ?? 0,
        head: PolicyInsureeDraft.fromJson(
          Map<String, dynamic>.from(json['head'] as Map),
        ),
        poverty: json['poverty'] == true,
        familyTypeId: json['familyTypeId']?.toString(),
        address: json['address']?.toString(),
        ethnicity: json['ethnicity']?.toString(),
        confirmationNumber: json['confirmationNumber']?.toString(),
        confirmationTypeId: json['confirmationTypeId']?.toString(),
        isOffline: json['isOffline'] != false,
      );

  Map<String, dynamic> toGraphQLInput(String clientMutationId) => {
    'clientMutationId': clientMutationId,
    'clientMutationLabel': application == PolicyApplication.hiv
        ? 'Create HIV beneficiary'
        : 'Create CSU beneficiary',
    'locationId': locationId,
    'poverty': poverty,
    if (_present(familyTypeId)) 'familyTypeId': familyTypeId,
    if (_present(address)) 'address': address!.trim(),
    if (_present(ethnicity)) 'ethnicity': ethnicity,
    if (_present(confirmationNumber))
      'confirmationNo': confirmationNumber!.trim(),
    if (_present(confirmationTypeId)) 'confirmationTypeId': confirmationTypeId,
    'isOffline': isOffline,
    'headInsuree': head.toGraphQLInput(application, forFamilyHead: true),
  };
}

class PolicyDraft {
  const PolicyDraft({
    required this.familyId,
    required this.enrolmentDate,
    required this.startDate,
    required this.expiryDate,
    required this.value,
    required this.productId,
    required this.officerId,
    this.productCode,
    this.policyNumber,
    this.pregnancyAge,
    this.isChequeSante = false,
  });

  final int familyId;
  final DateTime enrolmentDate;
  final DateTime startDate;
  final DateTime expiryDate;
  final num value;
  final int productId;
  final int officerId;
  final String? productCode;
  final String? policyNumber;
  final int? pregnancyAge;
  final bool isChequeSante;

  PolicyDraft withFamilyId(int value) => PolicyDraft(
    familyId: value,
    enrolmentDate: enrolmentDate,
    startDate: startDate,
    expiryDate: expiryDate,
    value: this.value,
    productId: productId,
    officerId: officerId,
    productCode: productCode,
    policyNumber: policyNumber,
    pregnancyAge: pregnancyAge,
    isChequeSante: isChequeSante,
  );

  Map<String, dynamic> toJson() => {
    'familyId': familyId,
    'enrolmentDate': enrolmentDate.toIso8601String(),
    'startDate': startDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'value': value,
    'productId': productId,
    'officerId': officerId,
    'productCode': productCode,
    'policyNumber': policyNumber,
    'pregnancyAge': pregnancyAge,
    'isChequeSante': isChequeSante,
  };

  factory PolicyDraft.fromJson(Map<String, dynamic> json) => PolicyDraft(
    familyId: _int(json['familyId']) ?? 0,
    enrolmentDate: DateTime.parse(json['enrolmentDate'].toString()),
    startDate: DateTime.parse(json['startDate'].toString()),
    expiryDate: DateTime.parse(json['expiryDate'].toString()),
    value: json['value'] as num,
    productId: _int(json['productId']) ?? 0,
    officerId: _int(json['officerId']) ?? 0,
    productCode: json['productCode']?.toString(),
    policyNumber: json['policyNumber']?.toString(),
    pregnancyAge: _int(json['pregnancyAge']),
    isChequeSante: json['isChequeSante'] == true,
  );

  Map<String, dynamic> toGraphQLInput(String clientMutationId) {
    if (familyId <= 0 || productId <= 0 || officerId <= 0) {
      throw const FormatException(
        'Policy requires server family, product, and officer IDs.',
      );
    }
    if (expiryDate.isBefore(startDate)) {
      throw const FormatException('Policy expiry must follow its start date.');
    }
    if (isChequeSante &&
        (pregnancyAge == null || pregnancyAge! < 1 || pregnancyAge! > 42)) {
      throw const FormatException(
        'Pregnancy week is required and must be between 1 and 42.',
      );
    }
    return {
      'clientMutationId': clientMutationId,
      'clientMutationLabel': 'Create Policy',
      'familyId': familyId,
      'enrollDate': _date(enrolmentDate),
      'startDate': _date(startDate),
      'expiryDate': _date(expiryDate),
      'value': value,
      'productId': productId,
      'officerId': officerId,
      if (_present(policyNumber)) 'policyNumber': policyNumber!.trim(),
      if (pregnancyAge != null) 'pregnancyAge': pregnancyAge,
    };
  }
}

String _date(DateTime value) => value.toIso8601String().substring(0, 10);

bool _present(String? value) => value?.trim().isNotEmpty == true;

int? _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
