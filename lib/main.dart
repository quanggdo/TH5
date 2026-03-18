import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/connectivity_service.dart';
import 'providers/habit_provider.dart';
import 'providers/calendar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Services
  final localStorageService = LocalStorageService();
  final firestoreService = FirestoreService();
  final connectivityService = ConnectivityService();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        // Services (inject qua Provider để các widget con có thể truy cập)
        Provider<AuthService>.value(value: authService),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<LocalStorageService>.value(value: localStorageService),
        Provider<FirestoreService>.value(value: firestoreService),

        // Providers (inject Services qua constructor — DI pattern)
        ChangeNotifierProvider<HabitProvider>(
          create: (_) => HabitProvider(localStorageService)..loadHabits(),
        ),
        ChangeNotifierProvider<CalendarProvider>(
          create: (_) =>
              CalendarProvider(firestoreService, localStorageService),
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
      home: const MyHomePage(title: 'TH5 - Habit Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (Firebase.apps.isNotEmpty) ...[
              const Icon(Icons.cloud_done, color: Colors.green, size: 50),
              const Text(
                'Firebase Connected!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Project: ${Firebase.apps.first.options.projectId}'),
              const SizedBox(height: 20),
            ],
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
