import 'dart:convert';
import 'dart:io';

import 'package:donut_server/donut_server.dart';

/// A Lambda custom runtime: asks the runtime API for each event, handles it
/// and reports back. Compiled to a native Linux binary named bootstrap.
Future<void> main() async {
  final api = Platform.environment['AWS_LAMBDA_RUNTIME_API']!;
  final region = Platform.environment['AWS_REGION']!;
  final credentials = AwsCredentials.fromEnvironment();
  final store = S3Store(bucket: Platform.environment['TABLES_BUCKET']!, region: region, credentials: credentials);
  final http = HttpClient();
  final base = 'http://$api/2018-06-01/runtime/invocation';

  Future<void> post(String path, Object body) async {
    final request = await http.postUrl(Uri.parse('$base/$path'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    await (await request.close()).drain<void>();
  }

  while (true) {
    final next = await (await http.getUrl(Uri.parse('$base/next'))).close();
    final id = next.headers.value('lambda-runtime-aws-request-id')!;
    final body = await utf8.decodeStream(next);
    try {
      final event = Map<String, dynamic>.from(jsonDecode(body) as Map);
      final context = Map<String, dynamic>.from(event['requestContext'] as Map);
      final sender = ApiGatewaySender(
          endpoint: '${context['domainName']}/${context['stage']}', region: region, credentials: credentials);
      await PartyServer(store: store, sender: sender).handle(event);
      await post('$id/response', {'statusCode': 200});
    } catch (error, stack) {
      stderr.writeln('$error\n$stack');
      await post('$id/error', {'errorMessage': '$error', 'errorType': error.runtimeType.toString()});
    }
  }
}
