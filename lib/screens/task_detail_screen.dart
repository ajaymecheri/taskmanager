import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Watch for live updates
    final provider = context.watch<TaskProvider>();
    final liveTask = provider.tasks.where((t) => t.id == task.id).firstOrNull;
    final currentTask = liveTask ?? task;

    final priorityColor = switch (currentTask.priority) {
      TaskPriority.high => AppTheme.errorColor,
      TaskPriority.medium => AppTheme.warningColor,
      TaskPriority.low => AppTheme.successColor,
    };
    final priorityLabel = switch (currentTask.priority) {
      TaskPriority.high => 'High Priority',
      TaskPriority.medium => 'Medium Priority',
      TaskPriority.low => 'Low Priority',
    };

    final isOverdue =
        !currentTask.isCompleted && currentTask.dueDate.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTaskScreen(task: currentTask),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            onPressed: () => _deleteTask(context, currentTask.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentTask.isCompleted
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentTask.isCompleted
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 16,
                        color: currentTask.isCompleted
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentTask.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: currentTask.isCompleted
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 14, color: priorityColor),
                      const SizedBox(width: 6),
                      Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              currentTask.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
                decoration:
                    currentTask.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (currentTask.description.isNotEmpty) ...[
              Text(
                currentTask.description,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info cards
            _buildInfoCard(
              icon: Icons.calendar_today,
              label: 'Due Date',
              value: DateFormat('EEEE, MMMM dd, yyyy').format(currentTask.dueDate),
              valueColor: isOverdue ? AppTheme.errorColor : null,
              trailing: isOverdue
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.access_time,
              label: 'Created',
              value: DateFormat('MMMM dd, yyyy – hh:mm a')
                  .format(currentTask.createdDate),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: currentTask.isSynced ? Icons.cloud_done : Icons.cloud_off,
              label: 'Sync Status',
              value: currentTask.isSynced
                  ? 'Synced with cloud'
                  : 'Pending sync',
              valueColor: currentTask.isSynced
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
            const SizedBox(height: 32),

            // Toggle completion button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    provider.toggleCompletion(currentTask.id),
                icon: Icon(
                  currentTask.isCompleted
                      ? Icons.undo
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  currentTask.isCompleted
                      ? 'Mark as Pending'
                      : 'Mark as Completed',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTask.isCompleted
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  void _deleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(taskId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
