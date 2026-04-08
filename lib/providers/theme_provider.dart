import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const _keyDark = 'isDarkMode';

  bool _isDark;
  final Box _box;

  Offset? rippleOrigin;
  bool isAnimating = false;

  bool get isDark => _isDark;

  ThemeProvider(this._isDark, this._box);

  /// 立即切换主题 + 触发波纹动画
  Future<void> startRipple(Offset origin) async {
    rippleOrigin = origin;
    isAnimating = true;
    _isDark = !_isDark;
    await _box.put(_keyDark, _isDark);
    notifyListeners();
  }

  /// 动画结束后由 overlay 调用，清理状态
  void onAnimationDone() {
    isAnimating = false;
    rippleOrigin = null;
    notifyListeners();
  }
}
