import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Lightweight wrapper around the Tenor v2 API.
///
/// Free key: https://developers.google.com/tenor/guides/quickstart
/// Set  TENOR_API_KEY=<your_key>  in assets/env/app_env.
class TenorService {
  TenorService._();

  static const _base = 'https://tenor.googleapis.com/v2';

  /// Returns the CDN URL of the first GIF for [query], or `null` on failure.
  ///
  /// Results are safe-for-work unless [contentFilter] is changed.
  static Future<String?> fetchGifUrl(
    String query, {
    String contentFilter = 'medium', // off | low | medium | high
    String mediaFilter = 'gif',
  }) async {
    final apiKey = dotenv.env['TENOR_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_TENOR_API_KEY') {
      developer.log(
        'TENOR_API_KEY not set in app_env — GIFs will not load.',
        name: 'TenorService',
      );
      return null;
    }

    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'key': apiKey,
      'client_key': 'mixvy',
      'limit': '1',
      'contentfilter': contentFilter,
      'media_filter': mediaFilter,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        developer.log(
          'Tenor API error ${response.statusCode}: ${response.body}',
          name: 'TenorService',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final media = (results.first['media_formats'] as Map<String, dynamic>?);
      if (media == null) return null;

      // Prefer gif → mediumgif → tinygif
      for (final key in ['gif', 'mediumgif', 'tinygif']) {
        final url = (media[key] as Map<String, dynamic>?)?['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
      return null;
    } on Exception catch (e, st) {
      developer.log(
        'Tenor fetch failed for "$query"',
        name: 'TenorService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
