import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/esim_capabilities.dart';
import '../models/esim_install_result.dart';
import '../models/lpa_activation_code.dart';
import 'method_channel_esim_provisioning.dart';

/// The interface that implementations of `esim_provisioning` must implement.
abstract class EsimProvisioningPlatform extends PlatformInterface {
  /// Constructs an [EsimProvisioningPlatform] verifying identity token.
  EsimProvisioningPlatform() : super(token: _token);

  static final Object _token = Object();

  static EsimProvisioningPlatform _instance = MethodChannelEsimProvisioning();

  /// The default instance of [EsimProvisioningPlatform] to use.
  static EsimProvisioningPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [EsimProvisioningPlatform] when they register themselves.
  static set instance(EsimProvisioningPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Checks whether the host device supports eSIM and queries eUICC hardware information.
  Future<EsimCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }

  /// Initiates eSIM profile installation.
  ///
  /// - On Android: Uses `EuiccManager` (Direct download if carrier-privileged, otherwise system dialog).
  /// - On iOS: Uses `CTCellularPlanProvisioning` if carrier-entitled, otherwise opens native cellular setup sheet.
  Future<EsimInstallResult> installProfile(
    LpaActivationCode code, {
    bool switchAfterDownload = true,
  }) {
    throw UnimplementedError('installProfile() has not been implemented.');
  }

  /// Opens the native OS cellular / SIM settings page.
  Future<bool> openCellularSettings() {
    throw UnimplementedError('openCellularSettings() has not been implemented.');
  }
}
