import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/esim_capabilities.dart';
import '../models/esim_install_result.dart';
import '../models/lpa_activation_code.dart';
import 'esim_provisioning_platform.dart';

/// MethodChannel implementation of [EsimProvisioningPlatform].
class MethodChannelEsimProvisioning extends EsimProvisioningPlatform {
  /// Creates a [MethodChannelEsimProvisioning] with an optional custom [channel].
  MethodChannelEsimProvisioning({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('dev.flutter.telecom/esim_provisioning');

  final MethodChannel _channel;

  /// Underlying platform binary channel.
  @visibleForTesting
  MethodChannel get channel => _channel;

  @override
  Future<EsimCapabilities> getCapabilities() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('getCapabilities');
    if (map == null) {
      return const EsimCapabilities(isSupported: false);
    }
    return EsimCapabilities.fromMap(map);
  }

  @override
  Future<EsimInstallResult> installProfile(
    LpaActivationCode code, {
    bool switchAfterDownload = true,
  }) async {
    final map = await _channel.invokeMapMethod<Object?, Object?>(
      'installProfile',
      <String, Object?>{
        'lpa': code.rawLpa,
        'smdpAddress': code.smdpAddress,
        'matchingId': code.matchingId,
        'confirmationCode': code.confirmationCode,
        'imei': code.imei,
        'switchAfterDownload': switchAfterDownload,
      },
    );
    if (map == null) {
      return const EsimInstallResult(
        status: EsimInstallStatus.failed,
        errorCode: EsimErrorCode.systemError,
        message: 'No response from native eSIM subsystem',
      );
    }
    return EsimInstallResult.fromMap(map);
  }

  @override
  Future<bool> openCellularSettings() async {
    final result = await _channel.invokeMethod<bool>('openCellularSettings');
    return result ?? false;
  }
}
