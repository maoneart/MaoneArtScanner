import 'dart:convert';
import 'dart:io';

class CaptchaSolverService {
  /// Diambil secara aman dari GitHub Secrets saat build via --dart-define=CAPSOLVER_API_KEY=...
  static const String apiKey = String.fromEnvironment('CAPSOLVER_API_KEY', defaultValue: '');

  /// Menandakan apakah API Key sudah terpasang
  static bool get isConfigured => apiKey.trim().isNotEmpty;

  /// SiteKey resmi reCAPTCHA Bapenda Jabar
  static const String bapendaJabarSiteKey = '6LdVj8cUAAAAAE1z6e6PZq-sX_v1dZ3zL_Q5q_8x';
  static const String bapendaJabarUrl = 'https://bapenda.jabarprov.go.id/infopkb/';

  /// Menyelesaikan reCAPTCHA v2 / Turnstile menggunakan CapSolver AI
  static Future<String?> solveRecaptcha({
    String websiteUrl = bapendaJabarUrl,
    String websiteKey = bapendaJabarSiteKey,
  }) async {
    if (!isConfigured) return null;

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      // 1. Buat Task Pemecahan Captcha
      final createUrl = Uri.parse('https://api.capsolver.com/createTask');
      final createReq = await client.postUrl(createUrl);
      createReq.headers.set('Content-Type', 'application/json');

      final taskPayload = {
        'clientKey': apiKey.trim(),
        'task': {
          'type': 'ReCaptchaV2TaskProxyless',
          'websiteURL': websiteUrl,
          'websiteKey': websiteKey,
        },
      };

      createReq.write(jsonEncode(taskPayload));
      final createRes = await createReq.close().timeout(const Duration(seconds: 15));
      final createBody = await createRes.transform(utf8.decoder).join();
      final createJson = jsonDecode(createBody) as Map<String, dynamic>;

      if (createJson['errorId'] != 0 && createJson['errorId'] != null) {
        return null;
      }

      // Jika langsung ready dalam request pertama
      if (createJson['status'] == 'ready' && createJson['solution'] != null) {
        final solution = createJson['solution'] as Map<String, dynamic>;
        return solution['gRecaptchaResponse']?.toString();
      }

      final taskId = createJson['taskId']?.toString();
      if (taskId == null || taskId.isEmpty) return null;

      // 2. Polling hasil task (maksimal 10 kali tiap 2 detik)
      final resultUrl = Uri.parse('https://api.capsolver.com/getTaskResult');
      for (int attempt = 0; attempt < 10; attempt++) {
        await Future.delayed(const Duration(milliseconds: 2000));

        final resultReq = await client.postUrl(resultUrl);
        resultReq.headers.set('Content-Type', 'application/json');
        resultReq.write(jsonEncode({
          'clientKey': apiKey.trim(),
          'taskId': taskId,
        }));

        final resultRes = await resultReq.close().timeout(const Duration(seconds: 10));
        final resultBody = await resultRes.transform(utf8.decoder).join();
        final resultJson = jsonDecode(resultBody) as Map<String, dynamic>;

        if (resultJson['status'] == 'ready' && resultJson['solution'] != null) {
          final solution = resultJson['solution'] as Map<String, dynamic>;
          return solution['gRecaptchaResponse']?.toString();
        }

        if (resultJson['status'] == 'failed' || (resultJson['errorId'] != 0 && resultJson['errorId'] != null)) {
          return null;
        }
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
    return null;
  }
}
