import 'package:meta/meta.dart';

import 'models/esim_capabilities.dart';
import 'models/esim_install_result.dart';
import 'models/lpa_activation_code.dart';
import 'platform_interface/esim_provisioning_platform.dart';

/// Client providing unified, production-grade eSIM (eUICC) profile provisioning and capability querying.
class EsimProvisioning {
  EsimProvisioning._internal() : _platformOverride = null;

  /// Creates an [EsimProvisioning] instance with a custom platform implementation (useful for unit testing).
  @visibleForTesting
  EsimProvisioning.custom({EsimProvisioningPlatform? platform})
      : _platformOverride = platform;

  /// Singleton instance of [EsimProvisioning].
  static final EsimProvisioning instance = EsimProvisioning._internal();

  final EsimProvisioningPlatform? _platformOverride;

  EsimProvisioningPlatform get _platform =>
      _platformOverride ?? EsimProvisioningPlatform.instance;

  /// Checks whether the host device contains an eUICC chip and what provisioning features are supported.
  Future<EsimCapabilities> getCapabilities() {
    return _platform.getCapabilities();
  }

  /// Installs an eSIM profile on the device using the provided [code] or [rawLpaString].
  ///
  /// Can be called either with an [LpaActivationCode] instance or a raw GSMA LPA string
  /// (e.g. `LPA:1$smdp.example.com$matching-id`).
  ///
  /// On Android, if [switchAfterDownload] is true, the OS automatically enables the newly installed
  /// subscription upon successful download.
  Future<EsimInstallResult> install({
    LpaActivationCode? code,
    String? rawLpaString,
    bool switchAfterDownload = true,
  }) async {
    assert(
      code != null || rawLpaString != null,
      'Either code or rawLpaString must be provided.',
    );

    final lpa = code ?? LpaActivationCode.tryParse(rawLpaString);
    if (lpa == null) {
      return const EsimInstallResult(
        status: EsimInstallStatus.failed,
        errorCode: EsimErrorCode.invalidActivationCode,
        message:
            'The provided activation code does not match GSMA SGP.22 standard.',
      );
    }

    final caps = await getCapabilities();
    if (!caps.isSupported) {
      return const EsimInstallResult(
        status: EsimInstallStatus.failed,
        errorCode: EsimErrorCode.unsupportedDevice,
        message: 'This device does not support eSIM (no eUICC chip detected).',
      );
    }

    return _platform.installProfile(
      lpa,
      switchAfterDownload: switchAfterDownload,
    );
  }

  /// Opens the native OS cellular / SIM management settings page.
  Future<bool> openCellularSettings() {
    return _platform.openCellularSettings();
  }
}
