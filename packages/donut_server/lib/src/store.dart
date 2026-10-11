import 'dart:convert';

import 'aws.dart';

/// A stored JSON document and the version it was read at.
class Stored {
  const Stored(this.json, this.etag);

  final Map<String, dynamic> json;
  final String etag;
}

/// Someone else wrote the document since it was read; read it again.
class Conflict implements Exception {
  const Conflict();
}

/// JSON documents with optimistic locking: a write can insist the document
/// is still the version it read ([ifMatch]) or doesn't exist yet
/// ([ifAbsent]), so two moves at once can't overwrite each other.
abstract interface class Store {
  Future<Stored?> get(String key);

  /// Returns the new version. Throws [Conflict] if the condition fails.
  Future<String> put(String key, Map<String, dynamic> json, {String? ifMatch, bool ifAbsent = false});

  Future<void> delete(String key);

  /// Up to [limit] keys starting with [prefix], in order.
  Future<List<String>> list(String prefix, {int limit = 20});
}

/// Documents in an S3 bucket, using its conditional writes.
class S3Store implements Store {
  S3Store({required this.bucket, required String region, required AwsCredentials credentials})
      : _host = '$bucket.s3.$region.amazonaws.com',
        _signer = SigV4(credentials, region: region, service: 's3');

  final String bucket;
  final String _host;
  final SigV4 _signer;

  String _path(String key) => '/${key.split('/').map(SigV4.encode).join('/')}';

  @override
  Future<Stored?> get(String key) async {
    final response = await awsRequest(_signer, method: 'GET', host: _host, path: _path(key), signPayloadHeader: true);
    if (response.status == 404 || response.status == 403) return null;
    if (response.status != 200) throw StateError('S3 GET $key: ${response.status} ${response.text}');
    return Stored(Map<String, dynamic>.from(jsonDecode(response.text) as Map), response.headers.value('etag')!);
  }

  @override
  Future<String> put(String key, Map<String, dynamic> json, {String? ifMatch, bool ifAbsent = false}) async {
    final response = await awsRequest(
      _signer,
      method: 'PUT',
      host: _host,
      path: _path(key),
      body: utf8.encode(jsonEncode(json)),
      headers: {
        'content-type': 'application/json',
        if (ifMatch != null) 'if-match': ifMatch,
        if (ifAbsent) 'if-none-match': '*',
      },
      signPayloadHeader: true,
    );
    // 412: the condition failed; 409: a conditional write raced another
    if (response.status == 412 || response.status == 409) throw const Conflict();
    if (response.status != 200) throw StateError('S3 PUT $key: ${response.status} ${response.text}');
    return response.headers.value('etag')!;
  }

  @override
  Future<void> delete(String key) async {
    await awsRequest(_signer, method: 'DELETE', host: _host, path: _path(key), signPayloadHeader: true);
  }

  @override
  Future<List<String>> list(String prefix, {int limit = 20}) async {
    final response = await awsRequest(_signer,
        method: 'GET',
        host: _host,
        path: '/',
        query: {'list-type': '2', 'prefix': prefix, 'max-keys': '$limit'},
        signPayloadHeader: true);
    if (response.status != 200) throw StateError('S3 LIST $prefix: ${response.status} ${response.text}');
    return [for (final match in RegExp(r'<Key>([^<]*)</Key>').allMatches(response.text)) match.group(1)!];
  }
}

/// Documents in memory, for tests.
class MemoryStore implements Store {
  final Map<String, (String, String)> _docs = {};
  int _version = 0;

  Iterable<String> get keys => _docs.keys;

  @override
  Future<Stored?> get(String key) async {
    final doc = _docs[key];
    return doc == null ? null : Stored(Map<String, dynamic>.from(jsonDecode(doc.$2) as Map), doc.$1);
  }

  @override
  Future<String> put(String key, Map<String, dynamic> json, {String? ifMatch, bool ifAbsent = false}) async {
    final existing = _docs[key];
    if (ifAbsent && existing != null) throw const Conflict();
    if (ifMatch != null && existing?.$1 != ifMatch) throw const Conflict();
    final etag = '"v${++_version}"';
    _docs[key] = (etag, jsonEncode(json));
    return etag;
  }

  @override
  Future<void> delete(String key) async => _docs.remove(key);

  @override
  Future<List<String>> list(String prefix, {int limit = 20}) async =>
      (_docs.keys.where((key) => key.startsWith(prefix)).toList()..sort()).take(limit).toList();
}
