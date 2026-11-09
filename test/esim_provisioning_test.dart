import 'package:esim_provisioning/esim_provisioning.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.flutter.telecom/esim_provisioning_unit');
  late MethodChannelEsimProvisioning platform;
  late EsimProvisioning client;

  setUp(() {
    platform = MethodChannelEsimProvisioning(channel: channel);
    client = EsimProvisioning.custom(platform: platform);
  });

  group('EsimProvisioning — MethodChannel & Client Behavior', () {
    test('queries capabilities correctly', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getCapabilities') {
          return <String, Object?>{
            'isSupported': true,
            'isEnabled': true,
            'eid': '89049032000000000000000000001234',
            'hasCarrierPrivileges': true,
            'supportsDirectDownload': true,
            'supportsSystemDialog': true,
            'osVersion': 'Android 14 (API 34)',
          };
        }
        return null;
      });

      final caps = await client.getCapabilities();
      expect(caps.isSupported, isTrue);
      expect(caps.isEnabled, isTrue);
      expect(caps.eid, '89049032000000000000000000001234');
      expect(caps.hasCarrierPrivileges, isTrue);
      expect(caps.supportsDirectDownload, isTrue);
    });

    test('installs profile successfully on supported device', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getCapabilities') {
          return <String, Object?>{'isSupported': true};
        }
        if (call.method == 'installProfile') {
          final args = call.arguments as Map<Object?, Object?>;
          expect(args['smdpAddress'], 'smdp.example.com');
          expect(args['matchingId'], 'TEST-1234');
          return <String, Object?>{
            'status': 'success',
            'errorCode': 'none',
            'message': 'Profile installed successfully.',
          };
        }
        return null;
      });

      final result = await client.install(
        rawLpaString: 'LPA:1\$smdp.example.com\$TEST-1234',
      );
      expect(result.isSuccess, isTrue);
      expect(result.errorCode, EsimErrorCode.none);
    });

    test('fails immediately when device does not support eSIM without invoking install', () async {
      var installCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getCapabilities') {
          return <String, Object?>{'isSupported': false};
        }
        if (call.method == 'installProfile') {
          installCalled = true;
          return null;
        }
        return null;
      });

      final result = await client.install(
        rawLpaString: 'LPA:1\$smdp.example.com\$TEST-1234',
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, EsimErrorCode.unsupportedDevice);
      expect(installCalled, isFalse);
    });

    test('fails gracefully when LPA string is malformed', () async {
      final result = await client.install(rawLpaString: 'CORRUPTED_STRING');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, EsimErrorCode.invalidActivationCode);
    });

    test('opens cellular settings', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'openCellularSettings') {
          return true;
        }
        return null;
      });

      final opened = await client.openCellularSettings();
      expect(opened, isTrue);
    });
  });
}
