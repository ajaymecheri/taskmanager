# Task Manager

A Flutter task management application with Firebase Cloud Firestore and local storage (Hive).

## Features

- Create, edit, delete, and mark tasks as completed/pending
- Offline-first: works without internet, syncs when connectivity returns
- Search tasks by title
- Filter: All / Completed / Pending
- Sort: Due Date / Priority
- Real-time sync indicator (Synced / Syncing / Offline)
- Form validation and error handling

## Architecture

```
lib/
├── main.dart                  # App entry point, Provider setup
├── firebase_options.dart      # Generated Firebase config
├── models/
│   ├── task_model.dart        # Task data class with toJson/fromJson
│   └── task_model_adapter.dart # Hive TypeAdapter
├── services/
│   ├── firestore_service.dart     # Firestore CRUD operations
│   ├── local_storage_service.dart # Hive local persistence
│   ├── sync_service.dart          # Bidirectional sync logic
│   └── connectivity_service.dart  # Network state monitoring
├── providers/
│   └── task_provider.dart     # Business logic & state management
├── screens/
│   ├── task_list_screen.dart      # Main task list with search/filter/sort
│   ├── add_edit_task_screen.dart   # Create/edit task form
│   └── task_detail_screen.dart    # Task detail view
└── utils/
    └── app_theme.dart         # App-wide theme constants
```

**State Management:** Provider + ChangeNotifier  
**Remote Storage:** Firebase Cloud Firestore  
**Local Storage:** Hive  
**Connectivity:** connectivity_plus  

### Data Flow

1. Tasks are always saved to Hive first (offline-first)
2. If online, changes are pushed to Firestore immediately
3. When connectivity resumes, unsynced local changes are pushed to Firestore
4. On app start, local data loads instantly, then a full sync merges remote changes

## Setup

### Prerequisites

- Flutter SDK (≥ 3.10)
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- An Android device/emulator or iOS simulator

### Steps

1. **Clone and install dependencies**
   ```bash
   cd task_manager
   flutter pub get
   ```

2. **Configure Firebase**
   ```bash
   firebase login
   flutterfire configure --project=<your-firebase-project-id>
   ```
   This generates `lib/firebase_options.dart` and platform-specific config files.

3. **Enable Cloud Firestore**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project → Databases & Storage → Cloud Firestore
   - Create database (test mode or production mode)
   - If production mode, update Rules tab:
     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /tasks/{taskId} {
           allow read, write: if true;
         }
       }
     }
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Task Model

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID |
| title | String | Task title |
| description | String | Task description |
| priorityIndex | int | 0=Low, 1=Medium, 2=High |
| dueDate | DateTime | Task due date |
| isCompleted | bool | Completion status |
| createdDate | DateTime | Creation timestamp |
| isSynced | bool | Whether synced to Firestore |
| isDeleted | bool | Soft-delete flag for sync |
