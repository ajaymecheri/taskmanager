import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/task_model_adapter.dart';
import 'providers/task_provider.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';
import 'screens/task_list_screen.dart';
import 'screens/add_edit_task_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await LocalStorageService.init();

  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProxyProvider<ConnectivityService, TaskProvider>(
          create: (context) => TaskProvider(
            connectivityService: context.read<ConnectivityService>(),
          ),
          update: (_, connectivity, previous) =>
              previous ?? TaskProvider(connectivityService: connectivity),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TaskListScreen(),
        routes: {
          '/add': (_) => const AddEditTaskScreen(),
        },
      ),
    );
  }
}
