import 'dart:async';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

/// Own authentication initialization so SDK errors/timeouts have a retry screen.
class AuthStartup extends StatefulWidget {
  const AuthStartup({
    super.key,
    required this.createConfig,
    required this.child,
    this.createAuth,
  });
  final ClerkAuthConfig Function() createConfig;
  final Widget child;
  final Future<ClerkAuthState> Function(ClerkAuthConfig config)? createAuth;

  @override
  State<AuthStartup> createState() => _AuthStartupState();
}

class _AuthStartupState extends State<AuthStartup> {
  ClerkAuthState? _auth;
  Timer? _timer;
  int _attempt = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final attempt = ++_attempt;
    final watch = Stopwatch()..start();
    _failed = false;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
      if (!mounted || attempt != _attempt) return;
      _attempt++;
      debugPrint('[Startup] Authentication initialization timed out');
      setState(() => _failed = true);
    });
    unawaited(() async {
      try {
        final config = widget.createConfig();
        final auth =
            await (widget.createAuth?.call(config) ??
                ClerkAuthState.create(config: config));
        if (!mounted || attempt != _attempt) {
          auth.terminate();
          return;
        }
        _timer?.cancel();
        debugPrint(
          '[Startup] Authentication ready in ${watch.elapsedMilliseconds}ms',
        );
        setState(() => _auth = auth);
      } catch (error) {
        if (!mounted || attempt != _attempt) return;
        _timer?.cancel();
        debugPrint(
          '[Startup] Authentication initialization failed after ${watch.elapsedMilliseconds}ms: $error',
        );
        setState(() => _failed = true);
      }
    }());
  }

  @override
  void dispose() {
    _attempt++;
    _timer?.cancel();
    _auth?.terminate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth != null) {
      return ClerkAuth(authState: auth, child: widget.child);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_failed) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _failed
                        ? 'Could not restore your session. Check your connection and try again.'
                        : 'Restoring your session...',
                    textAlign: TextAlign.center,
                  ),
                  if (_failed)
                    TextButton(
                      onPressed: () {
                        setState(_start);
                      },
                      child: const Text('Try again'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
