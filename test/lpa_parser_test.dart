import 'package:esim_provisioning/esim_provisioning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LpaActivationCode — GSMA SGP.22 Parser & Validator', () {
    test('parses valid minimal LPA string (smdp + matchingId)', () {
      const raw = 'LPA:1\$smdp.example.com\$1234-ABCD-5678-EFGH';
      final lpa = LpaActivationCode.parse(raw);

      expect(lpa.smdpAddress, 'smdp.example.com');
      expect(lpa.matchingId, '1234-ABCD-5678-EFGH');
      expect(lpa.confirmationCode, isNull);
      expect(lpa.imei, isNull);
      expect(lpa.rawLpa, raw);
    });

    test('parses valid full LPA string with confirmation code and targeted IMEI', () {
      const raw = 'LPA:1\$cust.prod.smdp.io\$ORD-9988-7766\$CONF1234\$860000000000000';
      final lpa = LpaActivationCode.parse(raw);

      expect(lpa.smdpAddress, 'cust.prod.smdp.io');
      expect(lpa.matchingId, 'ORD-9988-7766');
      expect(lpa.confirmationCode, 'CONF1234');
      expect(lpa.imei, '860000000000000');
    });

    test('generates correct Apple iOS 17.4+ Universal Link', () {
      final lpa = LpaActivationCode.parse('LPA:1\$smdp.io\$MATCH-123');
      final uri = lpa.toAppleUniversalLink();

      expect(uri.scheme, 'https');
      expect(uri.host, 'esimsetup.apple.com');
      expect(uri.path, '/esim_qrcode_provisioning');
      expect(uri.queryParameters['carddata'], 'LPA:1\$smdp.io\$MATCH-123');
    });

    test('throws MalformedLpaException on missing prefix or empty segments', () {
      expect(
        () => LpaActivationCode.parse('NOT_AN_LPA'),
        throwsA(isA<MalformedLpaException>()),
      );

      expect(
        () => LpaActivationCode.parse('LPA:1\$\$matchingId'),
        throwsA(isA<MalformedLpaException>()),
      );

      expect(
        () => LpaActivationCode.parse('LPA:1\$smdp.io\$'),
        throwsA(isA<MalformedLpaException>()),
      );
    });

    test('tryParse safely handles null, empty, and invalid inputs without throwing', () {
      expect(LpaActivationCode.tryParse(null), isNull);
      expect(LpaActivationCode.tryParse(''), isNull);
      expect(LpaActivationCode.tryParse('invalid_code'), isNull);
      expect(
        LpaActivationCode.tryParse('LPA:1\$smdp.com\$OK'),
        isNotNull,
      );
    });
  });
}
