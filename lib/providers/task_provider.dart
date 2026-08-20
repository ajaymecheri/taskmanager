import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

enum TaskFilter { all, completed, pending }

enum TaskSort { dueDate, priority }

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorageService = LocalStorageService();
  late final SyncService _syncService;
  final ConnectivityService connectivityService;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _isSyncing = false;
  String _searchQuery = '';
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dueDate;

  List<TaskModel> get tasks => _getFilteredTasks();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSyncing => _isSyncing;
  String get searchQuery => _searchQuery;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;

  TaskProvider({required this.connectivityService}) {
    _syncService = SyncService(_firestoreService, _localStorageService);
    connectivityService.addListener(_onConnectivityChanged);
    _loadTasks();
  }

  void _onConnectivityChanged() {
    if (connectivityService.isOnline) {
      syncTasks();
    }
  }

  List<TaskModel> _getFilteredTasks() {
    var filtered = List<TaskModel>.from(_tasks);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply filter
    switch (_filter) {
      case TaskFilter.completed:
        filtered = filtered.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.pending:
        filtered = filtered.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Apply sort
    switch (_sort) {
      case TaskSort.dueDate:
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case TaskSort.priority:
        filtered.sort((a, b) => b.priorityIndex.compareTo(a.priorityIndex));
        break;
    }

    return filtered;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = _localStorageService.getAllTasks();
      notifyListeners();

      if (connectivityService.isOnline) {
        await syncTasks();
      }
    } catch (e) {
      _error = 'Failed to load tasks: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncTasks() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      _tasks = await _syncService.fullSync();
      _error = null;
    } catch (e) {
      // Sync failed silently, keep local data
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priorityIndex: priority.index,
      dueDate: dueDate,
      createdDate: DateTime.now(),
      isSynced: false,
    );

    await _localStorageService.saveTask(task);
    _tasks.add(task);
    notifyListeners();

    if (connectivityService.isOnline) {
      try {
        await _firestoreService.addTask(task);
        final synced = task.copyWith(isSynced: true);
        await _localStorageService.saveTask(synced);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) _tasks[index] = synced;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to sync new task: $e');
      }
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final updated = task.copyWith(isSynced: false);
    await _localStorageService.saveTask(updated);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners();
    }

    if (connectivityService.isOnline) {
      try {
        await _firestoreService.updateTask(updated);
        final synced = updated.copyWith(isSynced: true);
        await _localStorageService.saveTask(synced);
        final i = _tasks.indexWhere((t) => t.id == task.id);
        if (i != -1) _tasks[i] = synced;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to sync updated task: $e');
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final deleted = task.copyWith(isDeleted: true, isSynced: false);
    await _localStorageService.saveTask(deleted);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();

    if (connectivityService.isOnline) {
      try {
        await _firestoreService.deleteTask(taskId);
        await _localStorageService.deleteTask(taskId);
      } catch (e) {
        debugPrint('Failed to sync deletion: $e');
      }
    }
  }

  Future<void> toggleCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    final toggled = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(toggled);
  }

  Future<void> refreshTasks() async {
    await _loadTasks();
  }

  @override
  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
