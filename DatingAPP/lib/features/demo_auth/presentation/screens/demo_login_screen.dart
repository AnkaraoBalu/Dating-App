import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../data/demo_auth_api.dart';
import '../../data/demo_session.dart';
import '../../../login/presentation/widgets/login_header.dart';
import '../../../login/presentation/widgets/login_scaffold.dart';

class DemoLoginScreen extends StatefulWidget {
  const DemoLoginScreen({super.key});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  final _api = DemoAuthApi();
  List<DemoAccount>? _accounts;
  String? _error;
  String? _loggingIn;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _error = null;
      _accounts = null;
    });
    try {
      final accounts = await _api.listAccounts();
      if (mounted) setState(() => _accounts = accounts);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _login(DemoAccount account) async {
    setState(() {
      _loggingIn = account.username;
      _error = null;
    });
    try {
      final token = await _api.login(account.username);
      if (!mounted) return;
      DemoSession.activate(
        DemoSession(accessToken: token, username: account.username),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loggingIn = null);
    }
  }

  @override
  Widget build(BuildContext context) => LoginScaffold(
    kind: LoginHeaderKind.social,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose a demo profile', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Development account · no password required',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_accounts == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          Text(
            _error!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
          TextButton(onPressed: _loadAccounts, child: const Text('Try again')),
        ],
        if (_accounts != null && _accounts!.isEmpty)
          const Text(
            'No demo profiles yet. Seed the development database first.',
          ),
        for (final account in _accounts ?? const <DemoAccount>[]) ...[
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(account.username.characters.first.toUpperCase()),
              ),
              title: Text(account.username),
              subtitle: Text(
                account.gender == 'woman' ? 'Demo woman' : 'Demo man',
              ),
              trailing: _loggingIn == account.username
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _loggingIn == null ? () => _login(account) : null,
            ),
          ),
        ],
      ],
    ),
  );
}
