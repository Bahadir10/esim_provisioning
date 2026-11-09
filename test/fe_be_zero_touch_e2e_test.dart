import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:esim_provisioning/esim_provisioning.dart';
import 'package:esim_provisioning/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _resolveGoEsimHarnessDir() {
  final candidates = <String>[
    'tool/go_esim_harness',
    '../tool/go_esim_harness',
  ];
  for (final rel in candidates) {
    final dir = Directory(rel);
    if (dir.existsSync()) {
      return dir.absolute.path;
    }
  }
  throw StateError('Could not locate tool/go_esim_harness directory.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'Zero-Touch Mutual BE (Go SM-DP+ Server) <-> FE (Flutter EsimProvisioning) E2E Verification',
    () async {
      final goDir = _resolveGoEsimHarnessDir();

      // 1. Spawn the real Go SM-DP+ server on an ephemeral port (127.0.0.1:0)
      final goProcess = await Process.start(
        'go',
        <String>['run', './cmd/server', '-addr', '127.0.0.1:0'],
        workingDirectory: goDir,
      );
      addTearDown(() {
        goProcess.kill();
      });

      final baseUrlCompleter = Completer<String>();
      goProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
        if (line.startsWith('HARNESS_LISTENING=')) {
          final url = line.substring('HARNESS_LISTENING='.length).trim();
          if (!baseUrlCompleter.isCompleted) {
            baseUrlCompleter.complete(url);
          }
        }
      });

      final httpBaseUrl = await baseUrlCompleter.future.timeout(
        const Duration(seconds: 15),
      );

      // 2. Set up Mock Platform Channel for testing installation
      const channel = MethodChannel('dev.flutter.telecom/esim_zero_touch_e2e');
      final platform = MethodChannelEsimProvisioning(channel: channel);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getCapabilities') {
          return <String, Object?>{
            'isSupported': true,
            'isEnabled': true,
            'hasCarrierPrivileges': true,
            'supportsDirectDownload': true,
          };
        }
        if (call.method == 'installProfile') {
          return <String, Object?>{
            'status': 'success',
            'errorCode': 'none',
            'message': 'Profile installed by test channel.',
          };
        }
        return null;
      });

      final client = EsimProvisioning.custom(platform: platform);
      final bridge = EsimHarnessBridge(
        engine: client,
        httpBaseUrl: httpBaseUrl,
      );
      addTearDown(bridge.dispose);

      // 3. Order an eSIM profile dynamically from the Go SM-DP+ server
      final lpa = await bridge.orderMockProfile(
        customerId: 'customer_istanbul_99',
        planName: 'Europe 20GB Unlimited',
      );

      expect(lpa.rawLpa, startsWith('LPA:1\$'));
      expect(lpa.matchingId, startsWith('ORD-'));

      // 4. Install the dynamically generated LPA through the client
      final installResult = await client.install(code: lpa);
      expect(installResult.isSuccess, isTrue);

      // 5. Notify the Go SM-DP+ server that the device has completed profile download
      await bridge.simulateDownload(lpa.matchingId);

      // 6. Verify that the Go SM-DP+ server reflects the downloaded state
      final profileStatus = await bridge.getProfileStatus(lpa.matchingId);
      expect(profileStatus['status'], 'downloaded');
      expect(profileStatus['planName'], 'Europe 20GB Unlimited');
    },
  );
}
