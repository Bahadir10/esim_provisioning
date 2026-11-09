import 'package:meta/meta.dart';

/// Normalized error codes across iOS (`CTCellularPlanProvisioningAddPlanResult`),
/// Android (`EuiccManager.EMBEDDED_SUBSCRIPTION_RESULT_*`), and network errors.
enum EsimErrorCode {
  /// No error occurred.
  none,

  /// Device hardware does not contain an eUICC chip.
  unsupportedDevice,

  /// Provided LPA activation string is malformed or invalid.
  invalidActivationCode,

  /// Device is carrier-locked (SIM locked) to a different mobile network operator.
  carrierLocked,

  /// eUICC internal non-volatile memory is full.
  insufficientMemory,

  /// Profile download or carrier handshake timed out.
  timeout,

  /// Network communication with SM-DP+ server failed.
  networkError,

  /// Installation was canceled by the user from the system setup sheet.
  operationCanceled,

  /// Internal platform or operating system error.
  systemError,
}

/// Installation status of an eSIM profile provisioning attempt.
enum EsimInstallStatus {
  /// Profile was installed successfully.
  success,

  /// User canceled the installation sheet or prompt.
  canceled,

  /// Installation failed with an error.
  failed,

  /// Unknown or indeterminate outcome.
  unknown,
}

/// Result of an eSIM installation or activation attempt.
@immutable
class EsimInstallResult {
  /// Creates an [EsimInstallResult] reporting the outcome of a profile download.
  const EsimInstallResult({
    required this.status,
    this.errorCode = EsimErrorCode.none,
    this.message,
    this.rawDetails = const <String, Object?>{},
  });

  /// Deserializes [EsimInstallResult] from a platform channel map.
  factory EsimInstallResult.fromMap(Map<Object?, Object?> map) {
    final statusStr = map['status'] as String? ?? 'unknown';
    final errorCodeStr = map['errorCode'] as String? ?? 'none';
    final rawDetailsMap = map['rawDetails'] as Map<Object?, Object?>?;

    return EsimInstallResult(
      status: EsimInstallStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => EsimInstallStatus.unknown,
      ),
      errorCode: EsimErrorCode.values.firstWhere(
        (e) => e.name == errorCodeStr,
        orElse: () => EsimErrorCode.systemError,
      ),
      message: map['message'] as String?,
      rawDetails: rawDetailsMap != null
          ? rawDetailsMap.map((k, v) => MapEntry(k.toString(), v))
          : const <String, Object?>{},
    );
  }

  /// High-level installation status ([EsimInstallStatus.success], [EsimInstallStatus.failed], etc.).
  final EsimInstallStatus status;

  /// Specific error categorization when status is not success.
  final EsimErrorCode errorCode;

  /// Human-readable explanation or platform diagnostic message.
  final String? message;

  /// Raw platform-specific error dictionary or intent extras.
  final Map<String, Object?> rawDetails;

  /// Whether the eSIM profile was successfully provisioned on the eUICC.
  bool get isSuccess => status == EsimInstallStatus.success;

  /// Whether the user dismissed or canceled the system installation dialog.
  bool get isCanceled => status == EsimInstallStatus.canceled;

  /// Serializes the result to a transport map.
  Map<String, Object?> toMap() => <String, Object?>{
        'status': status.name,
        'errorCode': errorCode.name,
        'message': message,
        'rawDetails': rawDetails,
      };

  @override
  String toString() =>
      'EsimInstallResult(status: ${status.name}, errorCode: ${errorCode.name}, message: "$message")';
}
