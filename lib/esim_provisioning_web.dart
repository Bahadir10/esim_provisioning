import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'src/models/esim_capabilities.dart';
import 'src/models/esim_install_result.dart';
import 'src/models/lpa_activation_code.dart';
import 'src/platform_interface/esim_provisioning_platform.dart';

/// Web implementation of [EsimProvisioningPlatform].
class EsimProvisioningWeb extends EsimProvisioningPlatform {
  /// Constructs an [EsimProvisioningWeb] platform implementation.
  EsimProvisioningWeb();

  /// Registers [EsimProvisioningWeb] as the default platform instance on Web.
  static void registerWith(Registrar registrar) {
    EsimProvisioningPlatform.instance = EsimProvisioningWeb();
  }

  @override
  Future<EsimCapabilities> getCapabilities() async {
    return const EsimCapabilities(
      isSupported: false,
      isEnabled: false,
      hasCarrierPrivileges: false,
      supportsDirectDownload: false,
      supportsSystemDialog: false,
      osVersion: 'Web Browser',
    );
  }

  @override
  Future<EsimInstallResult> installProfile(
    LpaActivationCode code, {
    bool switchAfterDownload = true,
  }) async {
    // On web, attempt redirecting to Apple Universal Link if on Safari / iOS browser
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    if (userAgent.contains('iphone') || userAgent.contains('ipad')) {
      final universalLink = code.toAppleUniversalLink();
      web.window.open(universalLink.toString(), '_blank');
      return const EsimInstallResult(
        status: EsimInstallStatus.success,
        message: 'Redirected to Apple eSIM Universal Link setup sheet.',
      );
    }

    return const EsimInstallResult(
      status: EsimInstallStatus.failed,
      errorCode: EsimErrorCode.unsupportedDevice,
      message:
          'Direct eSIM provisioning is not supported inside standard web browsers.',
    );
  }

  @override
  Future<bool> openCellularSettings() async {
    return false;
  }
}
