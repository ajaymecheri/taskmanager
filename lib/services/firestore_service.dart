import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  Future<List<TaskModel>> fetchTasks() async {
    final snapshot =
        await _tasksCollection.orderBy('createdDate', descending: true).get();
    return snapshot.docs
        .map((doc) => TaskModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> addTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  Stream<List<TaskModel>> tasksStream() {
    return _tasksCollection
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList());
  }
}
