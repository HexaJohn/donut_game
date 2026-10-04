import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A minimal client for a local Ollama server (https://ollama.com).
class OllamaClient {
  OllamaClient({required this.baseUrl, required this.model});

  final String baseUrl;
  final String model;

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  /// Installed model names, e.g. "gemma3:4b". Throws a readable message.
  Future<List<String>> models() async {
    try {
      final response = await http.get(_uri('/api/tags')).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) throw 'Ollama answered with an error (${response.statusCode}).';
      return [for (final m in jsonDecode(response.body)['models'] ?? []) m['name'] as String];
    } on TimeoutException {
      throw 'Ollama did not answer at $baseUrl.';
    } on String {
      rethrow;
    } catch (e) {
      throw 'Could not reach Ollama at $baseUrl. Is it running?';
    }
  }

  /// One chat turn. With [schema] (a JSON schema) the reply is JSON in that
  /// shape. Returns the reply text; throws on failure.
  Future<String> chat(
    List<Map<String, String>> messages, {
    Map<String, dynamic>? schema,
    double temperature = 0.9,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final response = await http
        .post(
          _uri('/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'stream': false,
            if (schema != null) 'format': schema,
            'options': {'temperature': temperature, 'num_predict': 160},
            // Keep the model loaded between turns of a game
            'keep_alive': '15m',
          }),
        )
        .timeout(timeout);
    if (response.statusCode != 200) throw 'Ollama error ${response.statusCode}: ${response.body}';
    return (jsonDecode(utf8.decode(response.bodyBytes))['message']?['content'] as String? ?? '').trim();
  }
}
