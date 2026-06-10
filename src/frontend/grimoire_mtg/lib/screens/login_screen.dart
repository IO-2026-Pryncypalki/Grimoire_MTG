import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_ext.dart';
import '../services/auth_service.dart';
import '../widgets/content_width.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: ContentWidth(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Scryphone',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(l10n.loginTagline),
                const SizedBox(height: 32),
                if (auth.error != null) ...[
                  Text(
                    auth.error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (auth.canRetryRestore) ...[
                  FilledButton.icon(
                    onPressed: auth.isLoading ? null : () => auth.retryRestoreSession(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: auth.isLoading ? null : () => auth.login(),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.loginGoogle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
