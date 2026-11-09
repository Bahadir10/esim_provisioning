/// Test harness bridge utilities for end-to-end integration testing of [EsimProvisioning].
///
/// Connects Flutter's client-side engine with the lightweight Go SM-DP+ backend harness
/// (`tool/go_esim_harness`) to verify profile ordering and download simulations.
library;

export 'src/harness/esim_harness_bridge.dart';
