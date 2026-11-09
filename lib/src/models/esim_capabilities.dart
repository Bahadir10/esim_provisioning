import 'package:meta/meta.dart';

/// Comprehensive snapshot of device eUICC hardware, carrier privileges, and eSIM provisioning capabilities.
@immutable
class EsimCapabilities {
  /// Creates an [EsimCapabilities] snapshot of device eSIM features.
  const EsimCapabilities({
    required this.isSupported,
    this.isEnabled = false,
    this.eid,
    this.hasCarrierPrivileges = false,
    this.supportsDirectDownload = false,
    this.supportsSystemDialog = false,
    this.osVersion,
  });

  /// Deserializes [EsimCapabilities] from a platform channel map.
  factory EsimCapabilities.fromMap(Map<Object?, Object?> map) {
    return EsimCapabilities(
      isSupported: map['isSupported'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? false,
      eid: map['eid'] as String?,
      hasCarrierPrivileges: map['hasCarrierPrivileges'] as bool? ?? false,
      supportsDirectDownload: map['supportsDirectDownload'] as bool? ?? false,
      supportsSystemDialog: map['supportsSystemDialog'] as bool? ?? false,
      osVersion: map['osVersion'] as String?,
    );
  }

  /// Whether the host device hardware contains an embedded UICC (eSIM chip).
  final bool isSupported;

  /// Whether the eUICC subsystem is enabled in system settings.
  final bool isEnabled;

  /// Embedded Identity Document (EID) 32-digit serial number, if permitted by OS permissions.
  final String? eid;

  /// Whether the running application possesses carrier privileges / entitlements:
  /// - iOS: `com.apple.developer.networking.carrier-proposals`
  /// - Android: UICC carrier privilege rules on the active SIM
  final bool hasCarrierPrivileges;

  /// Whether the app can silently download eSIM profiles in the background without user intervention.
  final bool supportsDirectDownload;

  /// Whether the OS provides a system-level eSIM download wizard sheet.
  final bool supportsSystemDialog;

  /// Normalized OS version string.
  final String? osVersion;

  /// Serializes the capabilities into a transport map.
  Map<String, Object?> toMap() => <String, Object?>{
        'isSupported': isSupported,
        'isEnabled': isEnabled,
        'eid': eid,
        'hasCarrierPrivileges': hasCarrierPrivileges,
        'supportsDirectDownload': supportsDirectDownload,
        'supportsSystemDialog': supportsSystemDialog,
        'osVersion': osVersion,
      };

  @override
  String toString() =>
      'EsimCapabilities(supported: $isSupported, enabled: $isEnabled, '
      'eid: ${eid != null ? "***${eid!.substring(eid!.length > 6 ? eid!.length - 6 : 0)}" : "none"}, '
      'carrierPrivileges: $hasCarrierPrivileges, directDownload: $supportsDirectDownload)';
}
