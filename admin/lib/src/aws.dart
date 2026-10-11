import 'dart:convert';
import 'dart:io';

import 'package:donut_server/donut_server.dart';

/// An object in the bucket and when it was last written.
class S3Object {
  const S3Object(this.key, this.modified);

  final String key;
  final DateTime modified;
}

/// The party server's AWS resources, read with the AWS CLI's own
/// credentials on this Mac (env vars, else the profile in ~/.aws).
class AdminAws {
  AdminAws._(this.credentials, this.region);

  final AwsCredentials credentials;
  final String region;
  String? _bucket;

  static const stack = 'donut-game';

  static AdminAws fromEnvironment() {
    final env = Platform.environment;
    final profile = env['AWS_PROFILE'] ?? 'default';
    final home = env['HOME'] ?? '';
    final credentials = env['AWS_ACCESS_KEY_ID'] != null && env['AWS_SECRET_ACCESS_KEY'] != null
        ? AwsCredentials(env['AWS_ACCESS_KEY_ID']!, env['AWS_SECRET_ACCESS_KEY']!, env['AWS_SESSION_TOKEN'])
        : _fromFile('$home/.aws/credentials', profile);
    final region =
        env['AWS_REGION'] ??
        env['AWS_DEFAULT_REGION'] ??
        _ini('$home/.aws/config', profile == 'default' ? 'default' : 'profile $profile')['region'] ??
        'us-east-2';
    return AdminAws._(credentials, region);
  }

  static AwsCredentials _fromFile(String path, String profile) {
    final section = _ini(path, profile);
    final key = section['aws_access_key_id'], secret = section['aws_secret_access_key'];
    if (key == null || secret == null) {
      throw StateError('No AWS credentials for profile "$profile" in $path. Run `aws configure` first.');
    }
    return AwsCredentials(key, secret, section['aws_session_token']);
  }

  /// The key = value lines of one [section] of an INI file.
  static Map<String, String> _ini(String path, String section) {
    final file = File(path);
    if (!file.existsSync()) return {};
    final values = <String, String>{};
    String? current;
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.startsWith('[') && line.endsWith(']')) {
        current = line.substring(1, line.length - 1).trim();
      } else if (current == section && line.contains('=')) {
        final at = line.indexOf('=');
        values[line.substring(0, at).trim()] = line.substring(at + 1).trim();
      }
    }
    return values;
  }

  /// The tables bucket, found from the stack that made it.
  Future<String> bucket() async {
    if (_bucket != null) return _bucket!;
    final signer = SigV4(credentials, region: region, service: 'cloudformation');
    final response = await awsRequest(
      signer,
      method: 'GET',
      host: 'cloudformation.$region.amazonaws.com',
      path: '/',
      query: {
        'Action': 'DescribeStackResource',
        'StackName': stack,
        'LogicalResourceId': 'TablesBucket',
        'Version': '2010-05-15',
      },
    );
    final match = RegExp(r'<PhysicalResourceId>([^<]+)</PhysicalResourceId>').firstMatch(response.text);
    if (response.status != 200 || match == null) {
      throw StateError('Couldn\'t find the $stack stack in $region (${response.status}).');
    }
    return _bucket = match.group(1)!;
  }

  SigV4 get _s3 => SigV4(credentials, region: region, service: 's3');

  Future<String> _host() async => '${await bucket()}.s3.$region.amazonaws.com';

  /// Every object under [prefix].
  Future<List<S3Object>> list(String prefix) async {
    final host = await _host();
    final objects = <S3Object>[];
    String? token;
    do {
      final response = await awsRequest(
        _s3,
        method: 'GET',
        host: host,
        path: '/',
        query: {'list-type': '2', 'prefix': prefix, if (token != null) 'continuation-token': token},
        signPayloadHeader: true,
      );
      if (response.status != 200) throw StateError('Listing $prefix failed (${response.status}).');
      final text = response.text;
      for (final item in RegExp(r'<Contents>(.*?)</Contents>', dotAll: true).allMatches(text)) {
        final body = item.group(1)!;
        final key = RegExp(r'<Key>([^<]*)</Key>').firstMatch(body)?.group(1);
        final modified = RegExp(r'<LastModified>([^<]*)</LastModified>').firstMatch(body)?.group(1);
        if (key != null && modified != null) objects.add(S3Object(_unescape(key), DateTime.parse(modified)));
      }
      token = RegExp(r'<NextContinuationToken>([^<]*)</NextContinuationToken>').firstMatch(text)?.group(1);
    } while (token != null);
    return objects;
  }

  /// The JSON document at [key], or null if it's gone.
  Future<Map<String, dynamic>?> getJson(String key) async {
    final response = await awsRequest(
      _s3,
      method: 'GET',
      host: await _host(),
      path: '/${key.split('/').map(SigV4.encode).join('/')}',
      signPayloadHeader: true,
    );
    if (response.status == 404 || response.status == 403) return null;
    if (response.status != 200) throw StateError('Reading $key failed (${response.status}).');
    return Map<String, dynamic>.from(jsonDecode(response.text) as Map);
  }

  /// Writes [json] at [key].
  Future<void> putJson(String key, Map<String, dynamic> json) async {
    final response = await awsRequest(
      _s3,
      method: 'PUT',
      host: await _host(),
      path: '/${key.split('/').map(SigV4.encode).join('/')}',
      body: utf8.encode(jsonEncode(json)),
      headers: {'content-type': 'application/json'},
      signPayloadHeader: true,
    );
    if (response.status != 200) throw StateError('Writing $key failed (${response.status}).');
  }

  Future<void> delete(String key) async {
    final response = await awsRequest(
      _s3,
      method: 'DELETE',
      host: await _host(),
      path: '/${key.split('/').map(SigV4.encode).join('/')}',
      signPayloadHeader: true,
    );
    if (response.status != 204 && response.status != 200) {
      throw StateError('Deleting $key failed (${response.status}).');
    }
  }

  static String _unescape(String xml) => xml
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
