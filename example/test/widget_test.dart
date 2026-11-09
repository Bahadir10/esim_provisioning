import 'package:esim_provisioning_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EsimExampleApp renders capabilities and install button', (
    WidgetTester tester,
  ) async {
    const channel = MethodChannel('dev.flutter.telecom/esim_provisioning');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'getCapabilities') {
        return <String, Object?>{
          'isSupported': true,
          'isEnabled': true,
          'eid': '89049032000000000000000000001234',
        };
      }
      return null;
    });

    await tester.pumpWidget(const EsimExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('eSIM Provisioning Example'), findsOneWidget);
    expect(find.text('Device eUICC Capabilities'), findsOneWidget);
    expect(find.text('eSIM Hardware Supported: true'), findsOneWidget);
    expect(find.text('Install eSIM Profile'), findsOneWidget);
  });
}
