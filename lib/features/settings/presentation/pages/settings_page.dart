import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/presentation/cubit/settings_cubit.dart';

/// The Settings & Privacy page (docs/08 F15): theme, units, opt-in reminders,
/// the offline affirmation, and the data-ownership actions (docs/08 F14).
///
/// Consumes the app-level [SettingsCubit] so theme changes take effect
/// immediately across the app.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state.settings;
          final cubit = context.read<SettingsCubit>();
          return ListView(
            children: [
              const _SectionHeader('Appearance'),
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemePreference>(
                  value: settings.theme,
                  onChanged: (v) => v == null ? null : cubit.setTheme(v),
                  items: const [
                    DropdownMenuItem(
                      value: ThemePreference.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Units'),
                trailing: DropdownButton<UnitSystem>(
                  value: settings.units,
                  onChanged: (v) => v == null ? null : cubit.setUnits(v),
                  items: const [
                    DropdownMenuItem(
                      value: UnitSystem.metric,
                      child: Text('Metric'),
                    ),
                    DropdownMenuItem(
                      value: UnitSystem.imperial,
                      child: Text('Imperial'),
                    ),
                  ],
                ),
              ),
              const _SectionHeader('Reminders'),
              SwitchListTile(
                title: const Text('Daily reminder'),
                subtitle: const Text('A gentle nudge to log. Off by default.'),
                value: settings.remindersEnabled,
                onChanged: cubit.setReminders,
              ),
              const _SectionHeader('Data'),
              const _OfflineAffirmation(),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Export backup'),
                subtitle: const Text(
                  'Copy an encrypted backup to the clipboard',
                ),
                onTap: () => _export(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Import backup'),
                subtitle: const Text(
                  'Paste a backup to restore (merges by id)',
                ),
                onTap: () => _import(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete all data'),
                subtitle: const Text('Permanent. Cannot be undone.'),
                onTap: () => _wipe(context),
              ),
              const ListTile(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text('Cloud sync'),
                subtitle: Text('Coming soon'),
                enabled: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.exportBackup();
    final backup = result.valueOrNull;
    if (backup == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not create a backup.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: backup));
    messenger.showSnackBar(
      const SnackBar(content: Text('Backup copied to clipboard')),
    );
  }

  Future<void> _import(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final controller = TextEditingController();
    final paste = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Paste your backup here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (paste == null || paste.trim().isEmpty) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.importBackup(paste.trim());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
            (f) => 'Import failed: ${f.message}',
            (r) => 'Restored ${r.rowsWritten} records',
          ),
        ),
      ),
    );
  }

  Future<void> _wipe(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete all data?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently erases everything. Type DELETE to '
                'confirm.',
              ),
              const SizedBox(height: AppTokens.space3),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'DELETE'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.wipeAll();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess ? 'All data deleted' : 'Could not delete data',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space1,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OfflineAffirmation extends StatelessWidget {
  const _OfflineAffirmation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        0,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              'Your data lives only on this device. LifeLedger works fully '
              'offline and never uploads anything.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
