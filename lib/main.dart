import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'models/exercise_type.dart';
import 'models/exercise.dart';
import 'models/exercise_action.dart';
import 'providers/workout_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 intl 中文 locale
  await initializeDateFormatting('zh_CN');

  // 初始化 Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // 注册适配器
  Hive.registerAdapter(ExerciseCategoryAdapter());
  Hive.registerAdapter(ExerciseTypeAdapter());
  Hive.registerAdapter(ExerciseStatusAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(ExerciseActionAdapter());

  // 打开数据库
  await DatabaseService.init();

  // 提前打开 settings box，供 ThemeProvider 同步使用
  final settingsBox = await Hive.openBox('settings');
  final isDark = settingsBox.get('isDarkMode', defaultValue: true) as bool;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark, settingsBox)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: const FitnessApp(),
    ),
  );
}
