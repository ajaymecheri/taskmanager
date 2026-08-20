import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

enum TaskPriority { low, medium, high }

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  int priorityIndex;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime createdDate;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  bool isDeleted;

  TaskPriority get priority => TaskPriority.values[priorityIndex];
  set priority(TaskPriority value) => priorityIndex = value.index;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.priorityIndex = 1,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdDate,
    this.isSynced = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priorityIndex': priorityIndex,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'createdDate': Timestamp.fromDate(createdDate),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priorityIndex: json['priorityIndex'] as int? ?? 1,
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdDate: (json['createdDate'] as Timestamp).toDate(),
      isSynced: true,
      isDeleted: false,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? priorityIndex,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdDate,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
