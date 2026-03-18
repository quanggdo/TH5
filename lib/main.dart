import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/connectivity_service.dart';
import 'providers/habit_provider.dart';
import 'providers/calendar_provider.dart';
import 'screens/home_screen.dart';

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
    return MaterialApp(
      title: 'TH5 - Habit Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
