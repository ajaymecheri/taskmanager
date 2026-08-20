import 'package:hive/hive.dart';
import '../models/task_model.dart';

class LocalStorageService {
  static const String _boxName = 'tasks';

  Box<TaskModel> get _box => Hive.box<TaskModel>(_boxName);

  static Future<void> init() async {
    await Hive.openBox<TaskModel>(_boxName);
  }

  List<TaskModel> getAllTasks() {
    return _box.values.where((task) => !task.isDeleted).toList();
  }

  List<TaskModel> getUnsyncedTasks() {
    return _box.values.where((task) => !task.isSynced).toList();
  }

  List<TaskModel> getDeletedTasks() {
    return _box.values.where((task) => task.isDeleted).toList();
  }

  Future<void> saveTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> saveAllTasks(List<TaskModel> tasks) async {
    final Map<String, TaskModel> entries = {
      for (var task in tasks) task.id: task
    };
    await _box.putAll(entries);
  }

  TaskModel? getTask(String id) {
    return _box.get(id);
  }
}
