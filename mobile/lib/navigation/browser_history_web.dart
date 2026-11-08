import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

/// 新しい履歴を作らず、ブラウザが移動した分だけ元の位置へ戻す。
bool restoreBrowserHistoryBy(int delta) {
  if (delta == 0) return true;
  final history = _window.getProperty<JSObject>('history'.toJS);
  history.callMethod<JSAny?>('go'.toJS, delta.toJS);
  return true;
}
