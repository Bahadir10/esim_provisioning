import 'dart:convert';
import 'dart:io';

import '../esim_provisioning_client.dart';
import '../models/lpa_activation_code.dart';

/// Test bridge connecting Flutter [EsimProvisioning] with the local Go SM-DP+ test harness.
class EsimHarnessBridge {
  /// Creates an [EsimHarnessBridge] instance bound to [engine] and [httpBaseUrl].
  EsimHarnessBridge({
    required this.engine,
    required this.httpBaseUrl,
  });

  /// The [EsimProvisioning] client instance being tested.
  final EsimProvisioning engine;

  /// Root URL of the Go SM-DP+ server (e.g. `http://127.0.0.1:8095`).
  final String httpBaseUrl;
  final HttpClient _httpClient = HttpClient();

  /// Orders a mock eSIM profile from the Go SM-DP+ server and returns a valid [LpaActivationCode].
  Future<LpaActivationCode> orderMockProfile({
    String? customerId,
    String? planName,
  }) async {
    final res = await _postJson('/api/esim/order', <String, Object?>{
      'customerId': customerId ?? 'test_user_1',
      'planName': planName ?? 'Global Unlimited 10GB',
    });
    final lpaStr = res['lpa'] as String;
    return LpaActivationCode.parse(lpaStr);
  }

  /// Queries the current server-side status of the profile (`available`, `downloaded`, `active`).
  Future<Map<String, dynamic>> getProfileStatus(String matchingId) async {
    final req = await _httpClient.getUrl(
      Uri.parse('$httpBaseUrl/api/esim/profiles/$matchingId'),
    );
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Tells the mock SM-DP+ server to mark the profile as downloaded by the device.
  Future<Map<String, dynamic>> simulateDownload(String matchingId) {
    return _postJson('/api/esim/simulate-download', <String, Object?>{
      'matchingId': matchingId,
    });
  }

  /// Tells the mock SM-DP+ server to configure a simulated error condition.
  Future<Map<String, dynamic>> simulateError(
    String matchingId,
    String errorCode,
  ) {
    return _postJson('/api/esim/simulate-error', <String, Object?>{
      'matchingId': matchingId,
      'errorCode': errorCode,
    });
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> payload,
  ) async {
    final req = await _httpClient.postUrl(Uri.parse('$httpBaseUrl$path'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(payload));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Closes the HTTP client resources.
  Future<void> dispose() async {
    _httpClient.close(force: true);
  }
}
