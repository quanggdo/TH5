import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/connectivity_service.dart';
import 'providers/habit_provider.dart';
import 'providers/calendar_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Bật tính năng Offline Data Persistence cho thiết bị (Firestore Cache)
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Khởi tạo Services
  final localStorageService = LocalStorageService();
  final firestoreService = FirestoreService();
  final connectivityService = ConnectivityService();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<AuthService>.value(value: authService),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<LocalStorageService>.value(value: localStorageService),
        Provider<FirestoreService>.value(value: firestoreService),
        
        // Theo dõi User Context (Đăng nhập)
        StreamProvider<User?>(
          create: (_) => authService.authStateChanges,
          initialData: null,
        ),

        // Habit Provider phụ thuộc vào UserContext thông qua ProxyProvider
        ChangeNotifierProxyProvider<User?, HabitProvider>(
          create: (_) => HabitProvider(localStorageService, firestoreService),
          update: (_, user, habitProvider) => 
              habitProvider!..updateUser(user?.uid),
        ),

        // Calendar Provider phụ thuộc vào UserContext và HabitProvider
        ChangeNotifierProxyProvider2<User?, HabitProvider, CalendarProvider>(
          create: (_) => CalendarProvider(firestoreService),
          update: (_, user, habitProvider, calendarProvider) =>
              calendarProvider!..update(user?.uid, habitProvider.activeHabits),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'TH5 - Habit Tracker',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        visualDensity: VisualDensity.standard,
        textTheme: Typography.material2021().black.apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            ),
        scaffoldBackgroundColor: const Color(0xFFF7F4FA),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              TextStyle(color: colorScheme.onSurface),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.inverseSurface,
          contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        ),
        dialogTheme: DialogThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerTheme: DividerThemeData(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      // Cấu hình danh sách Menu màn hình (Router)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
      },
      home: Consumer<User?>(
        builder: (context, user, child) {
          // Nếu có user: vào Home, chưa có: mở màn Login
          if (user != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
