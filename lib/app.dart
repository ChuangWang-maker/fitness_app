import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'widgets/theme_ripple_overlay.dart';
import 'services/sound_service.dart';

const _primaryOrange = Color(0xFFFF6D00);
const _secondaryBlue = Color(0xFF1976D2);

class FitnessApp extends StatefulWidget {
  const FitnessApp({super.key});

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> {
  // ThemeData 只创建一次，主题切换不会重建 widget 树
  final _light = _lightTheme();
  final _dark = _darkTheme();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ThemeRippleOverlay(
          themeProvider: themeProvider,
          lightTheme: _light,
          darkTheme: _dark,
          child: MaterialApp(
            title: 'TrackFit',
            debugShowCheckedModeBanner: false,
            theme: _light,
            darkTheme: _dark,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            themeAnimationDuration: Duration.zero,
            home: const MainScaffold(),
          ),
        );
      },
    );
  }
}

ThemeData _darkTheme() {
  const bg = Color(0xFF121212);
  const card = Color(0xFF1E1E1E);
  const navBg = Color(0xFF1A1A1A);

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    cardColor: card,
    colorScheme: const ColorScheme.dark(
      primary: _primaryOrange,
      secondary: _secondaryBlue,
      surface: card,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _primaryOrange),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryOrange),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      hintStyle: const TextStyle(color: Color(0xFF616161)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navBg,
      selectedItemColor: _primaryOrange,
      unselectedItemColor: Color(0xFF757575),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF2A2A2A)),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData _lightTheme() {
  const bg = Color(0xFFF2F4F7);        // 蓝灰底色，比纯白有层次
  const card = Colors.white;
  const navBg = Colors.white;
  const textPrimary = Color(0xFF1A1A2E);
  const textSecondary = Color(0xFF6B7280);

  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    cardColor: card,
    colorScheme: const ColorScheme.light(
      primary: _primaryOrange,
      secondary: _secondaryBlue,
      surface: card,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _primaryOrange),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryOrange),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navBg,
      selectedItemColor: _primaryOrange,
      unselectedItemColor: Color(0xFFBDBDBD),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF323232),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── 主框架 ────────────────────────────────────────────────────
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '训练'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
        ],
      ),
    );
  }
}

/// 主题切换按钮 —— 放在 AppBar leading，捕获点击坐标传给 provider
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotate = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return IconButton(
      tooltip: isDark ? '切换亮色' : '切换暗色',
      onPressed: () {
        final box = context.findRenderObject() as RenderBox?;
        Offset origin = Offset.zero;
        if (box != null) {
          final local = Offset(box.size.width / 2, box.size.height / 2);
          origin = box.localToGlobal(local);
        }

        if (isDark) {
          _ctrl.forward(from: 0);
          SoundService.instance.playLightMode();
        } else {
          _ctrl.reverse(from: 1);
          SoundService.instance.playDarkMode();
        }
        themeProvider.startRipple(origin);
      },
      icon: RotationTransition(
        turns: _rotate,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            key: ValueKey(isDark),
          ),
        ),
      ),
    );
  }
}
