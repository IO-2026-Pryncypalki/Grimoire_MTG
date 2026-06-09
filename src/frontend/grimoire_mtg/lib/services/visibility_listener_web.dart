import 'dart:html' as html;

import 'visibility_listener_stub.dart';

html.EventListener? _listener;

void listenForVisibility(VisibilityCallback onChanged) {
  disposeVisibilityListener();
  _listener = (_) {
    onChanged(html.document.hidden != true);
  };
  html.document.addEventListener('visibilitychange', _listener!);
}

void disposeVisibilityListener() {
  if (_listener != null) {
    html.document.removeEventListener('visibilitychange', _listener!);
    _listener = null;
  }
}
