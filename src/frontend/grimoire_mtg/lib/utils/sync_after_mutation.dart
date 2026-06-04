import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';

Future<void> syncAfterLocalMutation(BuildContext context) async {
  await context.read<SyncService>().markSyncedAfterLocalWrite();
}
