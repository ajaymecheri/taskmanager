import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

class SyncService {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  SyncService(this._firestoreService, this._localStorageService);

  Future<void> syncToFirestore() async {
    // Upload unsynced local tasks
    final unsyncedTasks = _localStorageService.getUnsyncedTasks();
    for (final task in unsyncedTasks) {
      if (!task.isDeleted) {
        await _firestoreService.addTask(task);
        final synced = task.copyWith(isSynced: true);
        await _localStorageService.saveTask(synced);
      }
    }

    // Delete tasks marked for deletion
    final deletedTasks = _localStorageService.getDeletedTasks();
    for (final task in deletedTasks) {
      try {
        await _firestoreService.deleteTask(task.id);
      } catch (_) {
        // Task may not exist on server
      }
      await _localStorageService.deleteTask(task.id);
    }
  }

  Future<List<TaskModel>> syncFromFirestore() async {
    final remoteTasks = await _firestoreService.fetchTasks();

    // Merge: remote tasks are considered source of truth for synced items
    final localTasks = _localStorageService.getAllTasks();
    final localUnsyncedIds =
        _localStorageService.getUnsyncedTasks().map((t) => t.id).toSet();

    final mergedMap = <String, TaskModel>{};

    // Add remote tasks
    for (final task in remoteTasks) {
      mergedMap[task.id] = task;
    }

    // Keep local unsynced tasks (they haven't been pushed yet)
    for (final task in localTasks) {
      if (localUnsyncedIds.contains(task.id)) {
        mergedMap[task.id] = task;
      }
    }

    final merged = mergedMap.values.toList();
    await _localStorageService.saveAllTasks(merged);
    return merged;
  }

  Future<List<TaskModel>> fullSync() async {
    await syncToFirestore();
    return syncFromFirestore();
  }
}
