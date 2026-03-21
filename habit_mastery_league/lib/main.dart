import 'package:flutter/material.dart';
import 'app/app.dart';
import 'data/database/app_database.dart';

/// App entry point. Initializes the database before launching the UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database on startup so it's ready when screens load.
  await AppDatabase.getDatabase();

  runApp(const HabitMasteryApp());
}
