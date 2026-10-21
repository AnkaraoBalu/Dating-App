import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client that quietly retries GET requests when the network blips or
/// the API is still booting (Render answers 502/503/504 while it wakes up).
/// Only GETs are retried so a like, message or upload is never sent twice.
class RetryingClient extends http.BaseClient {
  RetryingClient([http.Client? inner]) : _inner = inner ?? http.Client();

  static const _delays = [Duration(seconds: 1), Duration(seconds: 3)];
  static const _retryStatuses = {502, 503, 504};

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET' || request is! http.Request) {
      return _inner.send(request);
    }
    for (var attempt = 0; ; attempt++) {
      final isLast = attempt >= _delays.length;
      try {
        final response = await _inner.send(
          attempt == 0 ? request : _copy(request),
        );
        if (isLast || !_retryStatuses.contains(response.statusCode)) {
          return response;
        }
        await response.stream.drain<void>();
        debugPrint(
          '[Network] GET ${request.url.path} returned '
          '${response.statusCode}; retrying.',
        );
      } on Object catch (error) {
        if (isLast || !isTransientNetworkError(error)) rethrow;
        debugPrint(
          '[Network] GET ${request.url.path} failed: $error; retrying.',
        );
      }
      await Future<void>.delayed(_delays[attempt]);
    }
  }

  http.Request _copy(http.Request original) =>
      http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection;

  @override
  void close() => _inner.close();
}

/// True for failures that usually clear up on their own: no connection,
/// dropped sockets, TLS hiccups or a request that took too long.
bool isTransientNetworkError(Object error) =>
    error is SocketException ||
    error is HandshakeException ||
    error is http.ClientException ||
    error is TimeoutException;
