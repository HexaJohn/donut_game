import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// AWS credentials, from the environment Lambda provides.
class AwsCredentials {
  const AwsCredentials(this.accessKey, this.secretKey, [this.sessionToken]);

  final String accessKey;
  final String secretKey;
  final String? sessionToken;

  static AwsCredentials fromEnvironment() => AwsCredentials(
        Platform.environment['AWS_ACCESS_KEY_ID']!,
        Platform.environment['AWS_SECRET_ACCESS_KEY']!,
        Platform.environment['AWS_SESSION_TOKEN'],
      );
}

/// Signs requests with AWS Signature Version 4.
class SigV4 {
  SigV4(this.credentials, {required this.region, required this.service});

  final AwsCredentials credentials;
  final String region;
  final String service;

  static String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String sha256Hex(List<int> bytes) => _hex(sha256.convert(bytes).bytes);

  static List<int> _hmac(List<int> key, String data) => Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  /// Percent-encodes everything but A-Z a-z 0-9 - _ . ~, as AWS wants.
  static String encode(String value) {
    final out = StringBuffer();
    for (final byte in utf8.encode(value)) {
      final c = String.fromCharCode(byte);
      if (RegExp(r'[A-Za-z0-9\-_.~]').hasMatch(c)) {
        out.write(c);
      } else {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }

  /// The headers that sign a request: [path] already percent-encoded, as it
  /// will be sent. S3 signs that path as is; every other service encodes it
  /// once more.
  Map<String, String> sign({
    required String method,
    required String host,
    required String path,
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
    List<int> body = const [],
    required DateTime time,
    bool signPayloadHeader = false,
  }) {
    final amzDate = '${time.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final date = amzDate.substring(0, 8);
    final payloadHash = sha256Hex(body);
    final all = <String, String>{
      ...headers.map((k, v) => MapEntry(k.toLowerCase(), v.trim())),
      'host': host,
      'x-amz-date': amzDate,
      if (signPayloadHeader) 'x-amz-content-sha256': payloadHash,
      if (credentials.sessionToken != null) 'x-amz-security-token': credentials.sessionToken!,
    };
    final names = all.keys.toList()..sort();
    final canonicalPath = service == 's3' ? path : path.split('/').map(encode).join('/');
    final canonicalQuery = (query.keys.toList()..sort()).map((k) => '${encode(k)}=${encode(query[k]!)}').join('&');
    final canonical = [
      method,
      canonicalPath,
      canonicalQuery,
      for (final name in names) '$name:${all[name]}',
      '',
      names.join(';'),
      payloadHash,
    ].join('\n');
    final scope = '$date/$region/$service/aws4_request';
    final toSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256Hex(utf8.encode(canonical))].join('\n');
    var key = _hmac(utf8.encode('AWS4${credentials.secretKey}'), date);
    key = _hmac(key, region);
    key = _hmac(key, service);
    key = _hmac(key, 'aws4_request');
    final signature = _hex(_hmac(key, toSign));
    return {
      ...all,
      'authorization': 'AWS4-HMAC-SHA256 Credential=${credentials.accessKey}/$scope, '
          'SignedHeaders=${names.join(';')}, Signature=$signature',
    }..remove('host');
  }
}

class AwsResponse {
  const AwsResponse(this.status, this.headers, this.body);

  final int status;
  final HttpHeaders headers;
  final Uint8List body;

  String get text => utf8.decode(body);
}

final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 5);

/// Sends a signed request to AWS over HTTPS.
Future<AwsResponse> awsRequest(
  SigV4 signer, {
  required String method,
  required String host,
  required String path,
  Map<String, String> headers = const {},
  List<int> body = const [],
  bool signPayloadHeader = false,
}) async {
  final signed = signer.sign(
    method: method,
    host: host,
    path: path,
    headers: headers,
    body: body,
    time: DateTime.now(),
    signPayloadHeader: signPayloadHeader,
  );
  final request = await _http.openUrl(method, Uri.parse('https://$host$path'));
  signed.forEach(request.headers.set);
  request.contentLength = body.length;
  if (body.isNotEmpty) request.add(body);
  final response = await request.close();
  final bytes = await response.fold<BytesBuilder>(BytesBuilder(), (b, chunk) => b..add(chunk));
  return AwsResponse(response.statusCode, response.headers, bytes.takeBytes());
}
