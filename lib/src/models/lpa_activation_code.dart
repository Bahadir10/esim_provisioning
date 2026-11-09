import 'package:meta/meta.dart';

/// Exception thrown when an LPA string does not conform to the GSMA SGP.22 standard.
class MalformedLpaException implements Exception {
  /// Creates a [MalformedLpaException] with descriptive [message] and optional [rawLpa].
  const MalformedLpaException(this.message, {this.rawLpa});

  /// Description of the parsing violation.
  final String message;

  /// The raw input string that failed validation.
  final String? rawLpa;

  @override
  String toString() => 'MalformedLpaException: $message (raw: "$rawLpa")';
}

/// Immutable representation of a GSMA SGP.22 LPA (Local Profile Assistant) activation code.
///
/// Format: `LPA:1$<SMDP_Address>$<Matching_ID>[$<Confirmation_Code>][$<IMEI>]`
/// Example: `LPA:1$smdp.example.com$1234-ABCD-5678-EFGH`
@immutable
class LpaActivationCode {
  /// Creates an [LpaActivationCode] with explicit parameters.
  const LpaActivationCode({
    required this.smdpAddress,
    required this.matchingId,
    this.confirmationCode,
    this.imei,
    String? rawLpa,
  }) : rawLpa = rawLpa ??
            'LPA:1\$$smdpAddress\$$matchingId'
                '${confirmationCode != null ? '\$$confirmationCode' : ''}'
                '${imei != null ? '\$$imei' : ''}';

  /// Parses a raw GSMA SGP.22 LPA string into an [LpaActivationCode].
  ///
  /// Throws [MalformedLpaException] if the string does not follow the standard syntax.
  factory LpaActivationCode.parse(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('LPA:1\$')) {
      throw MalformedLpaException(
        'Activation code must start with standard prefix "LPA:1\$"',
        rawLpa: input,
      );
    }

    final parts = trimmed.split('\$');
    if (parts.length < 3) {
      throw MalformedLpaException(
        'Activation code requires at least an SM-DP+ address and matching identifier',
        rawLpa: input,
      );
    }

    final smdpAddress = parts[1].trim();
    final matchingId = parts[2].trim();

    if (smdpAddress.isEmpty) {
      throw MalformedLpaException(
        'SM-DP+ address cannot be empty',
        rawLpa: input,
      );
    }

    if (matchingId.isEmpty) {
      throw MalformedLpaException(
        'Matching identifier cannot be empty',
        rawLpa: input,
      );
    }

    final confirmationCode =
        parts.length > 3 && parts[3].trim().isNotEmpty ? parts[3].trim() : null;
    final imei =
        parts.length > 4 && parts[4].trim().isNotEmpty ? parts[4].trim() : null;

    return LpaActivationCode(
      smdpAddress: smdpAddress,
      matchingId: matchingId,
      confirmationCode: confirmationCode,
      imei: imei,
      rawLpa: trimmed,
    );
  }

  /// Attempts to parse [input], returning `null` if the string is malformed.
  static LpaActivationCode? tryParse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      return LpaActivationCode.parse(input);
    } on MalformedLpaException {
      return null;
    }
  }

  /// Fully-qualified domain name (FQDN) or IP of the SM-DP+ server (e.g. `smdp.example.com`).
  final String smdpAddress;

  /// Unique matching identifier / activation code assigned to this eSIM profile.
  final String matchingId;

  /// Optional confirmation code (PIN) if mandated by the carrier profile.
  final String? confirmationCode;

  /// Optional targeted device IMEI identifier.
  final String? imei;

  /// Full normalized GSMA LPA string.
  final String rawLpa;

  /// Returns the Apple official iOS 17.4+ eSIM Universal Link URL.
  ///
  /// Opening this link in Safari or via `openUrl` opens the native Apple Cellular Setup sheet.
  Uri toAppleUniversalLink() {
    return Uri.parse(
      'https://esimsetup.apple.com/esim_qrcode_provisioning?carddata='
      '${Uri.encodeComponent(rawLpa)}',
    );
  }

  /// Serializes the LPA parameters into a transport map.
  Map<String, Object?> toMap() => <String, Object?>{
        'smdpAddress': smdpAddress,
        'matchingId': matchingId,
        'confirmationCode': confirmationCode,
        'imei': imei,
        'rawLpa': rawLpa,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LpaActivationCode &&
          other.smdpAddress == smdpAddress &&
          other.matchingId == matchingId &&
          other.confirmationCode == confirmationCode &&
          other.imei == imei;

  @override
  int get hashCode =>
      Object.hash(smdpAddress, matchingId, confirmationCode, imei);

  @override
  String toString() => rawLpa;
}
