import 'package:flutter/services.dart';

bool _selectHandledOnDown = false;
bool _backHandledOnDown = false;

/// Handles Android TV D-Pad center (`select`), `enter`, `space`, `numpadEnter`,
/// and `gameButtonA` cleanly without double-triggering when both KeyDownEvent
/// and KeyUpEvent are emitted, while still supporting TV remotes that only
/// emit KeyUpEvent for `LogicalKeyboardKey.select`.
bool isTvActivateEvent(
  KeyEvent event, {
  bool includeMediaPlayPause = false,
}) {
  final key = event.logicalKey;
  final isActivate =
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA ||
      (includeMediaPlayPause && key == LogicalKeyboardKey.mediaPlayPause);

  if (!isActivate) return false;

  if (key == LogicalKeyboardKey.select) {
    if (event is KeyDownEvent) {
      _selectHandledOnDown = true;
      return true;
    }
    if (event is KeyUpEvent) {
      if (_selectHandledOnDown) {
        _selectHandledOnDown = false;
        return false;
      }
      return true;
    }
    return false;
  }

  return event is KeyDownEvent;
}

/// Handles TV remote Back (`goBack`, `escape`, `browserBack`) without
/// double-popping routes when both KeyDownEvent and KeyUpEvent fire.
bool isTvBackEvent(KeyEvent event) {
  final key = event.logicalKey;
  final isBack =
      key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.goBack ||
      key == LogicalKeyboardKey.browserBack;
  if (!isBack) return false;

  if (event is KeyDownEvent) {
    _backHandledOnDown = true;
    return true;
  }
  if (event is KeyUpEvent) {
    if (_backHandledOnDown) {
      _backHandledOnDown = false;
      return false;
    }
    return true;
  }
  return false;
}
