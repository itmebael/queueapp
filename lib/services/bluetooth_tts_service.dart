import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'tts_wrapper.dart' show TtsInterface, createTts, TtsStub;
// flutter_tts is commented out in pubspec.yaml to avoid Windows CMake errors

/// Service for managing Bluetooth-connected TTS devices per department
/// Each department can have its own Bluetooth speaker device
class BluetoothTtsService {
  static final BluetoothTtsService _instance = BluetoothTtsService._internal();
  factory BluetoothTtsService() => _instance;
  BluetoothTtsService._internal();

  TtsInterface? _tts;
  bool _ttsAvailable = false;
  final Map<String, BluetoothDevice?> _departmentDevices = {};
  final Map<String, BluetoothCharacteristic?> _departmentCharacteristics = {};
  final Map<String, bool> _departmentConnected = {};
  
  bool _isInitialized = false;
  bool _isBluetoothEnabled = false;
  bool _isBluetoothSupported = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to initialize TTS
      try {
        _tts = createTts();
        debugPrint('TTS instance created: ${_tts.runtimeType}');
        
        // WindowsTtsImpl is a valid TTS implementation (uses PowerShell)
        // Only TtsStub means TTS is not available
        if (_tts is TtsStub) {
          _ttsAvailable = false;
          debugPrint('TTS using stub implementation (TTS not available on this platform)');
        } else {
          // Configure TTS settings (WindowsTtsImpl methods are no-ops, but that's OK)
          try {
            await _tts!.setLanguage("en-US");
            await _tts!.setSpeechRate(0.5);
            await _tts!.setVolume(1.0);
            await _tts!.setPitch(1.0);
          } catch (e) {
            debugPrint('TTS configuration warning (non-critical): $e');
          }
          _ttsAvailable = true;
          debugPrint('TTS initialized successfully - type: ${_tts.runtimeType}');
        }
      } catch (e) {
        print('TTS initialization failed: $e');
        _ttsAvailable = false;
        _tts = TtsStub(); // Use stub as fallback
      }

      // Check Bluetooth adapter state (only if supported)
      try {
        // Check if Bluetooth is supported on this platform
        try {
          _isBluetoothSupported = await FlutterBluePlus.isSupported;
        } catch (e) {
          // Platform doesn't support flutter_blue_plus (e.g., Windows)
          if (e.toString().contains('unsupported') || e.toString().contains('UnsupportedOperation')) {
            _isBluetoothSupported = false;
            // Silently handle unsupported platform - this is expected on Windows
            debugPrint('Bluetooth not supported on this platform (expected on Windows)');
          } else {
            rethrow;
          }
        }

        if (_isBluetoothSupported) {
          try {
            _isBluetoothEnabled = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;

            // Listen to Bluetooth adapter state changes
            _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
              _isBluetoothEnabled = state == BluetoothAdapterState.on;
            });
          } catch (e) {
            debugPrint('Error checking Bluetooth adapter state: $e');
            _isBluetoothEnabled = false;
          }
        } else {
          _isBluetoothEnabled = false;
          // Don't log - unsupported platform is expected behavior
        }
      } catch (e) {
        // Catch any other errors
        if (e.toString().contains('unsupported') || e.toString().contains('UnsupportedOperation')) {
          _isBluetoothSupported = false;
          _isBluetoothEnabled = false;
          // Silently handle unsupported platform
          debugPrint('Bluetooth not supported on this platform (expected on Windows)');
        } else {
          // Only log unexpected errors
          print('Bluetooth initialization failed: $e');
          _isBluetoothEnabled = false;
        }
      }

      // Load saved device connections for each department
      await _loadSavedDevices();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing BluetoothTtsService: $e');
      // Still mark as initialized to prevent retry loops
      _isInitialized = true;
    }
  }

  /// Load saved Bluetooth device connections from preferences
  Future<void> _loadSavedDevices() async {
    if (!_isBluetoothSupported) {
      // Skip loading devices if Bluetooth is not supported
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final departments = ['CAS', 'COED', 'CONHS', 'COENG', 'CIT', 'CGS'];
      
      for (final dept in departments) {
        final deviceId = prefs.getString('bluetooth_device_$dept');
        if (deviceId != null) {
          // Try to find the device
          try {
            final devices = FlutterBluePlus.connectedDevices;
            if (devices.isNotEmpty) {
              final device = devices.firstWhere(
                (d) => d.remoteId.toString() == deviceId,
                orElse: () => devices.first,
              );
              _departmentDevices[dept] = device;
              await _connectToDevice(dept, device);
            }
          } catch (e) {
            print('Could not restore device for $dept: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading saved devices: $e');
    }
  }

  /// Save Bluetooth device connection for a department
  Future<void> _saveDevice(String department, BluetoothDevice device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bluetooth_device_$department', device.remoteId.toString());
    } catch (e) {
      print('Error saving device: $e');
    }
  }

  /// Check if Bluetooth is supported on this platform
  bool get isBluetoothSupported => _isBluetoothSupported;

  /// Check if Bluetooth is available and enabled
  bool get isBluetoothAvailable => _isBluetoothSupported && _isBluetoothEnabled;

  /// Scan for available Bluetooth devices
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    if (!_isBluetoothSupported) {
      throw UnsupportedError('Bluetooth is not supported on this platform');
    }

    if (!_isBluetoothEnabled) {
      throw Exception('Bluetooth is not enabled');
    }

    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Wait for scan results
      final devices = <BluetoothDevice>[];
      await for (final result in FlutterBluePlus.scanResults) {
        for (final scanResult in result) {
          if (!devices.any((d) => d.remoteId == scanResult.device.remoteId)) {
            devices.add(scanResult.device);
          }
        }
      }
      
      // Stop scanning
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // Ignore stop scan errors (e.g., already stopped)
      }
      
      return devices;
    } catch (e) {
      // Handle specific error cases
      final errorString = e.toString();
      
      // User cancelled the device chooser (web platform)
      if (errorString.contains('User cancelled') || 
          errorString.contains('requestDevice') ||
          errorString.contains('NotFoundError')) {
        debugPrint('User cancelled Bluetooth device selection');
        throw Exception('Device selection cancelled. Please try again and select a device when prompted.');
      }
      
      // Already stopped scan error (not critical)
      if (errorString.contains('already stopped') || 
          errorString.contains('stopScan')) {
        debugPrint('Scan already stopped (non-critical)');
        return [];
      }
      
      // Other errors
      debugPrint('Error scanning for devices: $e');
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // Ignore stop scan errors
      }
      rethrow;
    }
  }

  /// Connect to a Bluetooth device for a specific department
  Future<bool> connectToDevice(String department, BluetoothDevice device) async {
    try {
      await _connectToDevice(department, device);
      await _saveDevice(department, device);
      return _departmentConnected[department] ?? false;
    } catch (e) {
      print('Error connecting to device for $department: $e');
      return false;
    }
  }

  /// Internal method to connect to device
  Future<void> _connectToDevice(String department, BluetoothDevice device) async {
    try {
      // Disconnect existing connection if any
      if (_departmentConnected[department] == true) {
        await disconnectDevice(department);
      }

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find the service and characteristic for audio/TTS
      BluetoothCharacteristic? characteristic;
      for (final service in services) {
        // Look for common audio/TTS service UUIDs
        for (final char in service.characteristics) {
          // Use any writable characteristic (in real scenario, use proper UUID)
          if (char.properties.write || char.properties.writeWithoutResponse) {
            characteristic = char;
            break;
          }
        }
        if (characteristic != null) break;
      }

      _departmentDevices[department] = device;
      _departmentCharacteristics[department] = characteristic;
      _departmentConnected[department] = true;

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _departmentConnected[department] = false;
        }
      });
    } catch (e) {
      print('Error connecting to device: $e');
      _departmentConnected[department] = false;
      rethrow;
    }
  }

  /// Disconnect from a department's Bluetooth device
  Future<void> disconnectDevice(String department) async {
    try {
      final device = _departmentDevices[department];
      if (device != null) {
        await device.disconnect();
      }
      _departmentDevices[department] = null;
      _departmentCharacteristics[department] = null;
      _departmentConnected[department] = false;
    } catch (e) {
      print('Error disconnecting device for $department: $e');
    }
  }

  /// Check if a department has a connected device
  bool isConnected(String department) {
    return _departmentConnected[department] ?? false;
  }

  /// Get connected device for a department
  BluetoothDevice? getDevice(String department) {
    return _departmentDevices[department];
  }

  Future<void> announceQueueNumber(String department, int queueNumber, {String? name}) async {
    try {
      final deptName = _getDepartmentName(department);
      String message;
      if (name != null && name.isNotEmpty) {
        message = "Attention $name for $deptName, queue number $queueNumber, please be ready.";
      } else {
        message = "Queue number $queueNumber for $deptName, please be ready.";
      }

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Next in queue announcement sent to $department Bluetooth device only');
            return;
          } catch (e) {
            debugPrint('Bluetooth device announcement failed for $department: $e');
            return;
          }
        }
      }
      
      debugPrint('No Bluetooth device connected for $department - falling back to local TTS');
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing queue number for $department: $e');
    }
  }

  /// Internal method to speak with TTS (handles platform availability)
  Future<void> _speakWithTts(String message) async {
    if (_tts != null) {
      try {
        await _tts!.speak(message);
      } catch (e) {
        print('TTS speak failed: $e');
      }
    } else {
      print('TTS not available. Message: $message');
    }
  }

  Future<void> announceStartup() async {
    try {
      await _speakWithTts("Queue Management System is ready. Welcome to Registrar!");
    } catch (e) {
      print('Error announcing startup: $e');
    }
  }

  Future<void> announceDepartmentStart(String department) async {
    try {
      final deptName = _getDepartmentName(department);
      final message = "$deptName department is now starting. Queue management system is active.";

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Department start announcement sent to $department Bluetooth device only');
            return;
          } catch (e) {
            debugPrint('Bluetooth device announcement failed for $department: $e');
            return;
          }
        }
      }
      
      debugPrint('No Bluetooth device connected for $department - falling back to local TTS');
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing department start for $department: $e');
    }
  }

  String _getDepartmentName(String code) {
    final deptNames = {
      'CAS': 'College of Arts and Sciences',
      'COED': 'College of Education',
      'CONHS': 'College of Nursing and Health Sciences',
      'COENG': 'College of Engineering',
      'CIT': 'College of Industrial Technology',
      'CGS': 'College of Graduating School',
    };
    return deptNames[code] ?? code;
  }

  Future<void> announceCalling(String department, int queueNumber, {String? name}) async {
    final deptName = _getDepartmentName(department);
    String message;
    if (name != null && name.isNotEmpty) {
      message = "Calling $name for $deptName, queue number $queueNumber. Please proceed to the counter.";
    } else {
      message = "Calling queue number $queueNumber for $deptName. Please proceed to the counter.";
    }

    try {
      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Calling announcement sent to $department Bluetooth device only');
            return;
          } catch (e) {
            debugPrint('Bluetooth device announcement failed for $department: $e');
            return;
          }
        }
      }
      
      debugPrint('No Bluetooth device connected for $department - falling back to local TTS');
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing calling for $department: $e');
    }
  }

  Future<void> announceCompletion(String department, String queueNumber) async {
    try {
      final deptName = _getDepartmentName(department);
      final message = "Queue number $queueNumber for $deptName is completed.";

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Completion announcement sent to $department Bluetooth device');
            await _speakWithTts(message);
            return;
          } catch (e) {
            debugPrint('Bluetooth completion announcement failed for $department: $e');
          }
        }
      }
      
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing completion for $department: $e');
    }
  }

  Future<void> announceIncomplete(String department, String queueNumber) async {
    try {
      final deptName = _getDepartmentName(department);
      final message = "Queue number $queueNumber for $deptName is incomplete.";

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Incomplete announcement sent to $department Bluetooth device');
            await _speakWithTts(message);
            return;
          } catch (e) {
            debugPrint('Bluetooth incomplete announcement failed for $department: $e');
          }
        }
      }

      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing incomplete for $department: $e');
    }
  }

  Future<void> announceNext(String department, String queueNumber, {String? name}) async {
    try {
      final deptName = _getDepartmentName(department);
      final message = name != null && name.isNotEmpty
          ? "Queue number $queueNumber for $deptName, $name, you're next."
          : "Queue number $queueNumber for $deptName, you're next.";

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Next announcement sent to $department Bluetooth device');
            await _speakWithTts(message);
            return;
          } catch (e) {
            debugPrint('Bluetooth next announcement failed for $department: $e');
          }
        }
      }
      
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing next for $department: $e');
    }
  }

  Future<void> announceReady(String department, String queueNumber, {String? name}) async {
    try {
      final deptName = _getDepartmentName(department);
      final message = name != null && name.isNotEmpty
          ? "Queue number $queueNumber for $deptName, $name, please be ready."
          : "Queue number $queueNumber for $deptName, please be ready.";

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Ready announcement sent to $department Bluetooth device');
            await _speakWithTts(message);
            return;
          } catch (e) {
            debugPrint('Bluetooth ready announcement failed for $department: $e');
          }
        }
      }
      
      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing ready for $department: $e');
    }
  }

  Future<void> announceQueueJoined(String department, int queueNumber, {String? name}) async {
    try {
      final deptName = _getDepartmentName(department);
      String message;
      if (name != null && name.isNotEmpty) {
        message = "Queueing successful in $deptName. $name, your queue number is $queueNumber.";
      } else {
        message = "Queueing successful in $deptName. Your queue number is $queueNumber.";
      }

      if (_departmentConnected[department] == true) {
        final characteristic = _departmentCharacteristics[department];
        if (characteristic != null) {
          try {
            final bytes = message.codeUnits;
            if (characteristic.properties.write) {
              await characteristic.write(bytes, withoutResponse: false);
            } else if (characteristic.properties.writeWithoutResponse) {
              await characteristic.write(bytes, withoutResponse: true);
            }
            debugPrint('Queue joined announcement sent to $department Bluetooth device');
            return;
          } catch (e) {
            debugPrint('Bluetooth announcement failed for $department: $e');
          }
        }
      }

      await _speakWithTts(message);
    } catch (e) {
      print('Error announcing queue joined: $e');
    }
  }

  Future<void> stopAnnouncement() async {
    if (_tts != null) {
      try {
        await _tts!.stop();
      } catch (e) {
        print('Error stopping announcement: $e');
      }
    }
  }

  bool get isTtsAvailable => _ttsAvailable;

  void dispose() {
    _adapterStateSubscription?.cancel();
    for (final dept in _departmentDevices.keys) {
      disconnectDevice(dept);
    }
    _departmentDevices.clear();
    _departmentCharacteristics.clear();
    _departmentConnected.clear();
  }
}
