import 'package:flutter_riverpod_template/feature/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/core/localization/app_localizations.dart';
import 'package:flutter_riverpod_template/core/native/app_permissions.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});
  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  final _statuses = <String, String>{};
  bool _busy = false;
  String? _error;
  static const _permissions = [
    (
      'camera',
      'Camera',
      'Insuree photos and insurance card scanning',
      Icons.camera_alt_outlined,
    ),
    (
      'photos',
      'Photos',
      'Select an insuree photo from your library',
      Icons.photo_library_outlined,
    ),
    (
      'location',
      'Location',
      'Location for enrolment and field visits while using the app',
      Icons.location_on_outlined,
    ),
  ];
  static const _labels = {
    'granted': 'Allowed',
    'limited': 'Selected photos only',
    'denied': 'Not allowed',
    'notRequested': 'Not requested',
    'restricted': 'Restricted by device',
    'unavailable': 'Unavailable on this device',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  Future<void> _refresh() async {
    final statuses = <String, String>{};
    for (final permission in _permissions) {
      try {
        statuses[permission.$1] = await AppPermissions.status(permission.$1);
      } catch (_) {
        statuses[permission.$1] = 'unavailable';
      }
    }
    if (mounted) setState(() => _statuses.addAll(statuses));
  }

  Future<void> _request(String permission) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await AppPermissions.request(permission);
      if (mounted) {
        setState(() {
          _statuses[permission] = status;
          if (status == 'denied') {
            _error =
                'Access was not granted. You can change it in device settings.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to request access on this device.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppAppBar(title: Text(context.tr('Permissions'))),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final permission in _permissions)
          Card(
            child: ListTile(
              leading: Icon(permission.$4),
              title: Text(context.tr(permission.$2)),
              subtitle: Text(
                '${context.tr(permission.$3)}\n${context.tr(_labels[_statuses[permission.$1]] ?? 'Checking…')}',
              ),
              isThreeLine: true,
              trailing: AppButton(
                variant: AppButtonVariant.text,
                onPressed:
                    _busy ||
                        _statuses[permission.$1] == 'granted' ||
                        _statuses[permission.$1] == 'unavailable' ||
                        _statuses[permission.$1] == null
                    ? null
                    : () => _request(permission.$1),
                child: Text(context.tr('Allow')),
              ),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) AppErrorMessage(message: context.tr(_error!)),
        AppButton(
          variant: AppButtonVariant.secondary,
          onPressed: _busy
              ? null
              : () async {
                  try {
                    await AppPermissions.openSettings();
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => _error = 'Unable to open device settings.',
                      );
                    }
                  }
                },
          child: Text(context.tr('Open Device Settings')),
        ),
      ],
    ),
  );
}
