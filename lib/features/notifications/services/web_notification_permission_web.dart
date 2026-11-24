import 'dart:js_interop';
import 'dart:js_interop_unsafe';

String _mapWebPermission(String? perm) {
  return switch (perm) {
    'granted' => 'granted',
    'denied' => 'permanentlyDenied',
    'default' => 'notDetermined',
    _ => 'unsupported',
  };
}

String checkWebNotificationStatus() {
  try {
    if (!globalContext.has('Notification')) return 'unsupported';
    final ctor = globalContext.getProperty<JSObject?>('Notification'.toJS);
    if (ctor == null) return 'unsupported';
    final perm = ctor.getProperty<JSString?>('permission'.toJS)?.toDart;
    return _mapWebPermission(perm);
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> requestWebNotificationPermission() async {
  try {
    if (!globalContext.has('Notification')) return 'unsupported';
    final ctor = globalContext.getProperty<JSObject?>('Notification'.toJS);
    if (ctor == null) return 'unsupported';
    final promise =
        ctor.callMethod<JSPromise<JSString>>('requestPermission'.toJS);
    final res = await promise.toDart;
    return _mapWebPermission(res.toDart);
  } catch (_) {
    return checkWebNotificationStatus();
  }
}
