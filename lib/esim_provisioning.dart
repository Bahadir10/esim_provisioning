/// Production-grade eSIM (eUICC) profile provisioning, capability detection,
/// and GSMA SGP.22 LPA activation parser for Flutter.
///
/// Supported platforms:
/// - iOS (`CTCellularPlanProvisioning` & Universal Links)
/// - Android (`EuiccManager` direct download & system dialog)
/// - Windows & macOS (Diagnostic capabilities & Cellular Settings deep-links)
/// - Web (Browser capability detection & Apple Universal Link fallback)
///
/// For end-to-end integration testing with the local Go SM-DP+ harness,
/// import `package:esim_provisioning/testing.dart`.
library;

export 'src/esim_provisioning_client.dart';
export 'src/models/esim_capabilities.dart';
export 'src/models/esim_install_result.dart';
export 'src/models/lpa_activation_code.dart';
export 'src/platform_interface/esim_provisioning_platform.dart';
export 'src/platform_interface/method_channel_esim_provisioning.dart';
