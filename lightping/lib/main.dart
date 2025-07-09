import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

// For keeping the screen on
import 'package:wakelock_plus/wakelock_plus.dart';

// For camera access
import 'package:camera/camera.dart';

// For local storage
import 'package:shared_preferences/shared_preferences.dart';

// For notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import our services
import 'services/light_detection_service.dart';
import 'services/sms_service.dart'; // Now contains WhatsApp service

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error initializing cameras: $e');
  }

  // Keep screen on
  WakelockPlus.enable();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightPing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash Screen with the curved banner logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check if phone number exists before navigating
    Timer(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      final savedNumber = prefs.getString('phone_number') ?? '';
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => savedNumber.isEmpty 
              ? const PhoneNumberScreen() 
              : const MainScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/lp_banner_curved.png', width: 300),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

// WhatsApp Setup Screen (formerly Phone Number Input Screen)
class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _phoneController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showApiKeyField = false;
  
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone_number') ?? '';
    final savedApiKey = prefs.getString('whatsapp_api_key') ?? '';
    
    setState(() {
      _phoneController.text = savedPhone;
      _apiKeyController.text = savedApiKey;
      _showApiKeyField = savedPhone.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Save phone number and API key to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', _phoneController.text);
      await prefs.setString('whatsapp_api_key', _apiKeyController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }
  
  void _proceedToApiKey() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _showApiKeyField = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            // Use the fixed logo_curved.png
            Image.asset('assets/images/logo_curved.png', height: 40),
            const SizedBox(width: 10),
            const Text(
              'LightPing',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activate WhatsApp Messaging',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                WhatsAppService.getActivationInstructions(),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Example: +1 (555) 123-4567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  // Simple regex for international phone format
                  // Can be adjusted based on your specific requirements
                  final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
                  if (!phoneRegExp.hasMatch(
                    value.replaceAll(RegExp(r'[\s()-]'), ''),
                  )) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Format: Include country code (e.g., +1 for US)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_showApiKeyField)
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API Key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the API key';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_showApiKeyField ? _savePhoneNumber : _proceedToApiKey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_showApiKeyField ? 'Activate' : 'Next', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Screen with Camera Feed
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isPingDetected = false;
  int _pingCount = 0;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  String _phoneNumber = '';
  String _apiKey = '';
  Timer? _pingAnalysisTimer;
  
  // Light detection service
  final LightDetectionService _lightDetectionService = LightDetectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera(_selectedCameraIndex);
    _initializeNotifications();
    _loadPhoneNumber();

    // Start analyzing camera feed for light changes
    _startPingAnalysis();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _pingAnalysisTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle management for camera
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_selectedCameraIndex);
    }
  }

  // Initialize the camera with given index
  Future<void> _initializeCamera(int cameraIndex) async {
    if (cameras.isEmpty) return;

    // Ensure index is within bounds
    if (cameraIndex >= cameras.length) {
      cameraIndex = 0;
    }

    // Dispose previous controller if exists
    await _cameraController?.dispose();

    // Create new controller
    final newController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    // Initialize controller
    try {
      await newController.initialize();
      if (mounted) {
        setState(() {
          _cameraController = newController;
          _selectedCameraIndex = cameraIndex;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _switchCamera() async {
    final newIndex = (_selectedCameraIndex + 1) % cameras.length;
    await _initializeCamera(newIndex);
  }

  // Initialize notifications
  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    // Use the proper icon for notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _notificationsPlugin.initialize(initSettings);
  }

  // Load saved user data
  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNumber = prefs.getString('phone_number') ?? '';
    final savedApiKey = prefs.getString('whatsapp_api_key') ?? '';
    setState(() {
      _phoneNumber = savedNumber;
      _apiKey = savedApiKey;
    });
  }

  // Show phone number edit dialog
  void _showPhoneNumberDialog() {
    final phoneController = TextEditingController(text: _phoneNumber);
    final apiKeyController = TextEditingController(text: _apiKey);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update WhatsApp Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Example: +1 (555) 123-4567',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Your WhatsApp API Key',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To get a new API key, send "I allow callmebot to send me messages" to +34 644 87 21 57',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newNumber = phoneController.text.trim();
              final newApiKey = apiKeyController.text.trim();
              
              if (newNumber.isNotEmpty && newApiKey.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('phone_number', newNumber);
                await prefs.setString('whatsapp_api_key', newApiKey);
                setState(() {
                  _phoneNumber = newNumber;
                  _apiKey = newApiKey;
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Start timer to analyze camera feed for light changes
  void _startPingAnalysis() {
    _pingAnalysisTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _analyzeFrame();
    });
  }

  // Analyze camera frame for light changes
  Future<void> _analyzeFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Capture image from camera
      final image = await _cameraController!.takePicture();
      
      // Use the light detection service to detect light changes
      final isPingDetected = await _lightDetectionService.detectLightChange(image);
      
      if (isPingDetected && !_isPingDetected) {
        // New ping detected
        setState(() {
          _isPingDetected = true;
          _pingCount++;
        });
        
        // Send notifications
        _sendNotifications();
        
        // Reset ping detection after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isPingDetected = false;
            });
          }
        });
      }
      
    } catch (e) {
      print('Error analyzing frame: $e');
    }
  }
  // Send notifications when ping detected
  Future<void> _sendNotifications() async {
    // Local notification
    const androidDetails = AndroidNotificationDetails(
      'light_ping_channel',
      'Light Ping Notifications',
      channelDescription: 'Notifications for detected light pings',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      0,
      'Light Ping Detected!',
      'A change in light intensity has been detected.',
      notificationDetails,
    );
    
    // Send WhatsApp notification using CallMeBot
    if (_phoneNumber.isNotEmpty && _apiKey.isNotEmpty) {
      final whatsappResult = await WhatsAppService.sendWhatsAppMessage(
        phoneNumber: _phoneNumber,
        apiKey: _apiKey,
      );

      if (whatsappResult) {
        print('WhatsApp message sent successfully to $_phoneNumber');
      } else {
        print('Failed to send WhatsApp message to $_phoneNumber');
      }
    } else {
      print('Cannot send WhatsApp message: phone number or API key is missing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showPhoneNumberDialog,
          child: Row(
            children: [
              // Use the fixed logo_curved.png
              Image.asset('assets/images/logo_curved.png', height: 40),
              const SizedBox(width: 10),
              const Text(
                'LightPing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'WhatsApp: ${_phoneNumber.isNotEmpty ? _phoneNumber : "Not Set"}',
                style: TextStyle(
                  fontSize: 12,
                  color: _phoneNumber.isEmpty || _apiKey.isEmpty ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Text(
            _isPingDetected ? 'PING DETECTED, VERIFY?' : 'NO CURRENT PING',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _isPingDetected ? Colors.red : Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Ping count
          Text(
            'Light Pings Detected: $_pingCount',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          // Camera preview
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 30),
          // Camera switch button
          ElevatedButton.icon(
            onPressed: cameras.length > 1 ? _switchCamera : null,
            icon: const Icon(Icons.switch_camera),
            label: const Text('Switch Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
