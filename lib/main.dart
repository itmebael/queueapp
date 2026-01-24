import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/welcome_screen.dart';
import 'services/supabase_service.dart';
import 'services/queue_notification_service.dart';
import 'services/department_service.dart';
import 'services/purpose_service.dart';
import 'services/course_service.dart';
import 'services/admin_service.dart';
import 'services/bluetooth_tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app first, then initialize services in the background
  runApp(const QueueManagementApp());

  // Initialize services asynchronously (non-blocking)
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    // Initialize Supabase
    await SupabaseService().initialize();
  } catch (e) {
    print('Error initializing Supabase: $e');
  }

  try {
    // Initialize departments, purposes, courses, and admin services
    await DepartmentService().initializeDefaultDepartments();
    await PurposeService().initializeDefaultPurposes();
    await CourseService().initializeDefaultCourses();
    AdminService().initializeDefaultAdmins();
  } catch (e) {
    print('Error initializing default data: $e');
  }

  try {
    // Initialize SMS notifications
    QueueNotificationService().initialize();
  } catch (e) {
    print('Error initializing SMS notifications: $e');
  }

  try {
    // Initialize Bluetooth TTS service (may fail on web, that's okay)
    await BluetoothTtsService().initialize();
    
    // Announce system startup - welcome message (only if Bluetooth initialized)
    try {
      await BluetoothTtsService().announceStartup();
    } catch (e) {
      // Silently fail - TTS might not be available on web
      print('TTS announcement skipped: $e');
    }
  } catch (e) {
    print('Bluetooth TTS initialization skipped (expected on web): $e');
  }

  // Start periodic cleanup of old entries and missed entries
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    try {
      await SupabaseService().checkExpiredCountdowns();
      await SupabaseService().removeMissedEntriesFromLiveQueue();
      await SupabaseService().cleanupOldEntries();
    } catch (e) {
      print('Error in periodic cleanup: $e');
    }
  });
}

class QueueManagementApp extends StatelessWidget {
  const QueueManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queue Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF263277),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.25,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.15,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF263277), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
