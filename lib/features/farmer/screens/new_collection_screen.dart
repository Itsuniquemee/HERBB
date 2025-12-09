import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/collection_provider.dart';

class NewCollectionScreen extends StatefulWidget {
  const NewCollectionScreen({super.key});

  @override
  State<NewCollectionScreen> createState() => _NewCollectionScreenState();
}

class _NewCollectionScreenState extends State<NewCollectionScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _weightController = TextEditingController();
  final _moistureController = TextEditingController();
  final _commonNameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _notesController = TextEditingController();

  final List<File> _images = [];
  double? _latitude;
  double? _longitude;
  double? _altitude;
  double? _accuracy;
  double? _temperature;
  double? _humidity;
  bool _isLoadingLocation = false;
  bool _isLoadingWeather = false;
  bool _isSubmitting = false;

  late stt.SpeechToText _speech;
  bool _isListeningSpecies = false;
  bool _isListeningWeight = false;
  bool _isListeningMoisture = false;
  bool _isListeningNotes = false;

  final List<String> _herbSpecies = [
    'Ashwagandha',
    'Tulsi',
    'Brahmi',
    'Neem',
    'Turmeric',
    'Ginger',
    'Aloe Vera',
    'Amla',
  ];

  // Species details map with common and scientific names
  final Map<String, Map<String, String>> _speciesDetails = {
    'Ashwagandha': {
      'commonName': 'Indian Ginseng',
      'scientificName': 'Withania somnifera',
    },
    'Tulsi': {
      'commonName': 'Holy Basil',
      'scientificName': 'Ocimum sanctum',
    },
    'Brahmi': {
      'commonName': 'Water Hyssop',
      'scientificName': 'Bacopa monnieri',
    },
    'Neem': {
      'commonName': 'Indian Lilac',
      'scientificName': 'Azadirachta indica',
    },
    'Turmeric': {
      'commonName': 'Haldi',
      'scientificName': 'Curcuma longa',
    },
    'Ginger': {
      'commonName': 'Adrak',
      'scientificName': 'Zingiber officinale',
    },
    'Aloe Vera': {
      'commonName': 'Ghritkumari',
      'scientificName': 'Aloe barbadensis miller',
    },
    'Amla': {
      'commonName': 'Indian Gooseberry',
      'scientificName': 'Phyllanthus emblica',
    },
  };

  final List<String> _soilTypes = [
    'Loamy',
    'Clay',
    'Sandy',
    'Silt',
    'Peaty',
    'Chalky',
    'Red Soil',
    'Black Soil',
    'Alluvial',
  ];

  final Map<String, String> _soilTypesHindi = {
    'Loamy': 'दोमट',
    'Clay': 'चिकनी मिट्टी',
    'Sandy': 'रेतीली',
    'Silt': 'गाद',
    'Peaty': 'पीटयुक्त',
    'Chalky': 'खड़िया',
    'Red Soil': 'लाल मिट्टी',
    'Black Soil': 'काली मिट्टी',
    'Alluvial': 'जलोढ़',
  };

  final List<String> _harvestMethods = [
    'Manual Harvesting',
    'Mechanical Harvesting',
    'Semi-Mechanical',
    'Selective Harvesting',
  ];

  final Map<String, String> _harvestMethodsHindi = {
    'Manual Harvesting': 'हाथ से कटाई',
    'Mechanical Harvesting': 'यांत्रिक कटाई',
    'Semi-Mechanical': 'अर्ध-यांत्रिक',
    'Selective Harvesting': 'चयनात्मक कटाई',
  };

  final List<String> _partCollectedOptions = [
    'Whole Plant',
    'Leaves',
    'Roots',
    'Flowers',
    'Seeds',
    'Bark',
    'Fruits',
    'Rhizome',
    'Stem',
  ];

  final Map<String, String> _partCollectedHindi = {
    'Whole Plant': 'पूरा पौधा',
    'Leaves': 'पत्तियां',
    'Roots': 'जड़ें',
    'Flowers': 'फूल',
    'Seeds': 'बीज',
    'Bark': 'छाल',
    'Fruits': 'फल',
    'Rhizome': 'प्रकंद',
    'Stem': 'तना',
  };

  String? _selectedSoilType;
  String? _selectedHarvestMethod;
  String? _selectedPartCollected;

  final List<String> _weatherConditions = [
    'Sunny',
    'Cloudy',
    'Partly Cloudy',
    'Rainy',
    'Drizzle',
    'Windy',
    'Humid',
  ];

  String? _selectedWeatherCondition;

  late Box _offlineQueueBox;
  late Box _cacheBox;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _initHive();
    _getCurrentLocation();
    _listenConnectivity();
    _restoreFormState();
  }

  Future<void> _initHive() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    _offlineQueueBox = await Hive.openBox('offlineQueue');
    _cacheBox = await Hive.openBox('cache');
    _loadCachedData();
    _sendQueuedSubmissions();
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        _sendQueuedSubmissions();
      }
    });
  }

  void _loadCachedData() {
    if (_cacheBox.containsKey('location')) {
      final loc = _cacheBox.get('location');
      _latitude = loc['latitude'];
      _longitude = loc['longitude'];
      _altitude = loc['altitude'];
      _accuracy = loc['accuracy'];
    }
    if (_cacheBox.containsKey('weather')) {
      final weather = _cacheBox.get('weather');
      _temperature = weather['temperature'];
      _humidity = weather['humidity'];
      _selectedWeatherCondition = weather['condition'];
      print('DEBUG: Loaded from cache - condition: $_selectedWeatherCondition');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speciesController.dispose();
    _weightController.dispose();
    _moistureController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (e.g., when returning from camera)
    print('DEBUG: App lifecycle state: $state');
    if (state == AppLifecycleState.paused) {
      // App going to background (camera opening) - save everything
      print('DEBUG: App pausing - saving form state');
      _saveFormState();
    } else if (state == AppLifecycleState.resumed) {
      print('DEBUG: App resumed - restoring form state');
      _restoreFormState();
      // Force a rebuild to ensure UI is in sync
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _saveFormState() async {
    try {
      final formState = {
        'species': _speciesController.text,
        'weight': _weightController.text,
        'moisture': _moistureController.text,
        'commonName': _commonNameController.text,
        'scientificName': _scientificNameController.text,
        'locationName': _locationNameController.text,
        'notes': _notesController.text,
        'selectedSoilType': _selectedSoilType,
        'selectedHarvestMethod': _selectedHarvestMethod,
        'selectedPartCollected': _selectedPartCollected,
        'selectedWeatherCondition': _selectedWeatherCondition,
        'latitude': _latitude,
        'longitude': _longitude,
        'altitude': _altitude,
        'accuracy': _accuracy,
        'temperature': _temperature,
        'humidity': _humidity,
        'imageCount': _images.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _cacheBox.put('temp_form_state', formState);
      print('DEBUG: Form state saved: ${formState.keys.length} fields');
    } catch (e) {
      print('DEBUG: Error saving form state: $e');
    }
  }

  Future<void> _restoreFormState() async {
    try {
      final formState = _cacheBox.get('temp_form_state');
      if (formState != null && formState is Map) {
        // Only restore if saved recently (within last 5 minutes)
        final timestamp = formState['timestamp'] as int?;
        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age < 300000) { // 5 minutes
            print('DEBUG: Restoring form state from ${age}ms ago');
            setState(() {
              _speciesController.text = formState['species'] ?? '';
              _weightController.text = formState['weight'] ?? '';
              _moistureController.text = formState['moisture'] ?? '';
              _commonNameController.text = formState['commonName'] ?? '';
              _scientificNameController.text = formState['scientificName'] ?? '';
              _locationNameController.text = formState['locationName'] ?? '';
              _notesController.text = formState['notes'] ?? '';
              _selectedSoilType = formState['selectedSoilType'];
              _selectedHarvestMethod = formState['selectedHarvestMethod'];
              _selectedPartCollected = formState['selectedPartCollected'];
              _selectedWeatherCondition = formState['selectedWeatherCondition'];
              _latitude = formState['latitude'];
              _longitude = formState['longitude'];
              _altitude = formState['altitude'];
              _accuracy = formState['accuracy'];
              _temperature = formState['temperature'];
              _humidity = formState['humidity'];
            });
            
            // Restore image paths if available
            final imagePaths = _cacheBox.get('temp_image_paths');
            if (imagePaths != null && imagePaths is List) {
              _images.clear();
              for (var path in imagePaths) {
                if (path is String && File(path).existsSync()) {
                  _images.add(File(path));
                }
              }
              print('DEBUG: Restored ${_images.length} images');
            }
            
            print('DEBUG: Form state restored successfully');
            return;
          }
        }
      }
      print('DEBUG: No recent form state to restore');
    } catch (e) {
      print('DEBUG: Error restoring form state: $e');
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _startListening(TextEditingController controller, String field) async {
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() {
      _isListeningSpecies = field == 'species';
      _isListeningWeight = field == 'weight';
      _isListeningMoisture = field == 'moisture';
      _isListeningNotes = field == 'notes';
    });

    // Get current locale from provider to determine speech language
    final localeProvider = context.read<LocaleProvider>();
    String localeId = (field == 'notes' && localeProvider.isHindi) ? 'hi_IN' : 'en_US';

    _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        setState(() {
          controller.text = result.recognizedWords;
        });
        if (result.finalResult) _stopListening();
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      localeId: localeId,
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListeningSpecies = false;
      _isListeningWeight = false;
      _isListeningMoisture = false;
      _isListeningNotes = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      print('DEBUG: Location fetched - Lat: ${position.latitude}, Lon: ${position.longitude}');
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = position.altitude;
        _accuracy = position.accuracy;
      });
      _cacheBox.put('location', {
        'latitude': _latitude,
        'longitude': _longitude,
        'altitude': _altitude,
        'accuracy': _accuracy,
      });
      
      // Get location name using reverse geocoding
      print('DEBUG: Fetching location name via reverse geocoding...');
      final locationName = await locationService.getLocationName(
        position.latitude,
        position.longitude,
      );
      
      print('DEBUG: Location name received: $locationName');
      
      if (locationName != null && mounted) {
        setState(() {
          _locationNameController.text = locationName;
        });
        // Cache location name
        _cacheBox.put('location_name', locationName);
        print('DEBUG: Location name set to field: $locationName');
      } else {
        print('DEBUG: Location name is null or widget not mounted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch location name. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      await _getWeatherData();
    } else {
      print('DEBUG: Position is null - location fetch failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch location. Please enable GPS and grant location permission.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _getWeatherData() async {
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final weatherService = WeatherService();
      final weatherData = await weatherService.getWeatherDataFree(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      print('DEBUG: Weather data received: $weatherData');
      
      if (weatherData != null) {
        final weatherCode = weatherData['weather_code'];
        final isDay = weatherData['is_day'] == 1;
        print('DEBUG: Raw weather code: $weatherCode (type: ${weatherCode.runtimeType}), is_day: $isDay');
        
        final code = (weatherCode is int) ? weatherCode : (weatherCode is double ? weatherCode.toInt() : 0);
        print('DEBUG: Converted weather code: $code');
        
        final condition = weatherService.getWeatherCondition(code, isDay: isDay);
        print('DEBUG: Weather condition: $condition');
        
        setState(() {
          _temperature = weatherData['temperature'] as double?;
          _humidity = weatherData['humidity'] as double?;
          _selectedWeatherCondition = condition;
        });
        
        print('DEBUG: Selected weather condition after setState: $_selectedWeatherCondition');
        
        _cacheBox.put('weather', {
          'temperature': _temperature,
          'humidity': _humidity,
          'condition': condition,
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching weather: $e');
    }

    setState(() {
      _isLoadingWeather = false;
    });
  }

  Future<void> _captureImage() async {
    try {
      if (_images.length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 images allowed')),
          );
        }
        return;
      }

      // Save form state AND user session before opening camera
      print('DEBUG: Saving form state and session before camera');
      await _saveFormState();
      
      // Save that user is actively using the camera to prevent logout
      await StorageService.saveData('camera_active', 'true');
      await StorageService.saveData('camera_timestamp', DateTime.now().millisecondsSinceEpoch.toString());
      
      // Store context before async operation
      final currentContext = context;
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 70,
      );

      print('DEBUG: Camera returned, pickedFile: ${pickedFile?.path}');
      
      // Clear camera active flag
      await StorageService.removeData('camera_active');
      await StorageService.removeData('camera_timestamp');

      // Only update state if image was actually picked and widget is still mounted
      if (pickedFile != null) {
        // Wait a brief moment for app to fully resume
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          setState(() {
            _images.add(File(pickedFile.path));
          });
          
          // Save image path to cache for persistence
          List<String> imagePaths = _images.map((f) => f.path).toList();
          await _cacheBox.put('temp_image_paths', imagePaths);
          print('DEBUG: Saved ${imagePaths.length} image paths');
          
          // Show confirmation that image was added
          if (mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('Image ${_images.length} added successfully'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        print('DEBUG: No image selected (user cancelled)');
      }
      // If pickedFile is null, user cancelled - do nothing
    } catch (e) {
      // Log error but don't show error message if user simply cancelled
      print('Camera error (might be user cancellation): $e');
      // Only show error if it's not a user cancellation and widget is mounted
      if (mounted && !e.toString().toLowerCase().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _sendQueuedSubmissions() async {
    if (_offlineQueueBox.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final collectionProvider = context.read<CollectionProvider>();

    final List keys = _offlineQueueBox.keys.toList();
    for (var key in keys) {
      final payload = Map<String, dynamic>.from(_offlineQueueBox.get(key));
      try {
        final response = await http.post(
          Uri.parse('https://herbal-trace-production.up.railway.app/api/v1/collections'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MjM1MDU2LCJleHAiOjE3NjUzMjE0NTZ9.obOcf9rK86hhrf4Xqq_4MvKoM20qKICNI6TXfblsKwU',
          },
          body: jsonEncode(payload),
        );

        final decoded = jsonDecode(response.body);
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            decoded['success'] == true) {
          await collectionProvider.createCollectionEvent(
            farmerId: authProvider.currentUser!.id,
            species: payload['species'],
            latitude: double.parse(payload['latitude']),
            longitude: double.parse(payload['longitude']),
            imagePaths: List<String>.from(payload['imagePaths'] ?? []),
            weight: double.tryParse(payload['quantity'].toString()),
            moisture: double.tryParse(payload['moisture']?.toString() ?? '0'),
            temperature: payload['temperature'],
            humidity: payload['humidity'],
            commonName: payload['commonName'],
            scientificName: payload['scientificName'],
            harvestMethod: payload['harvestMethod'],
            partCollected: payload['partCollected'],
            altitude: payload['altitude'],
            locationName: payload['locationName'],
            soilType: payload['soilType'],
            notes: payload['notes'],
          );
          _offlineQueueBox.delete(key);
        }
      } catch (_) {
        // Leave in queue, retry later
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one image')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final collectionProvider = context.read<CollectionProvider>();

    final payload = {
      "species": _speciesController.text,
      "quantity": double.tryParse(_weightController.text) ?? 0,
      "unit": "kg",
      "harvestDate": DateTime.now().toIso8601String().split('T')[0],
      "latitude": _latitude!.toString(),
      "longitude": _longitude!.toString(),
      "accuracy": _accuracy,
      "altitude": _altitude,
      "location":
      "Lat: ${_latitude!.toStringAsFixed(6)}, Lon: ${_longitude!.toStringAsFixed(6)}",
      "imagePaths": _images.map((f) => f.path).toList(),
      "temperature": _temperature,
      "humidity": _humidity,
      "weatherCondition": _selectedWeatherCondition,
      "moisture": double.tryParse(_moistureController.text),
      "commonName": _commonNameController.text.isNotEmpty ? _commonNameController.text : null,
      "scientificName": _scientificNameController.text.isNotEmpty ? _scientificNameController.text : null,
      "harvestMethod": _selectedHarvestMethod,
      "partCollected": _selectedPartCollected,
      "locationName": _locationNameController.text.isNotEmpty ? _locationNameController.text : null,
      "soilType": _selectedSoilType,
      "notes": _notesController.text.isNotEmpty ? _notesController.text : null,
    };

    print('📤 Submitting collection to Railway backend...');
    print('📍 GPS: Lat=${_latitude}, Lon=${_longitude}, Accuracy=${_accuracy}m, Alt=${_altitude}m');
    print('🌡️  Weather: ${_selectedWeatherCondition}, Temp=${_temperature}°C, Humidity=${_humidity}%');
    print('📦 Payload: ${jsonEncode(payload)}');

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        await _offlineQueueBox.add(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet. Submission queued!')),
        );
        _showSuccessDialog('queued');
      } else {
        final response = await http.post(
          Uri.parse('https://herbal-trace-production.up.railway.app/api/v1/collections'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MjM1MDU2LCJleHAiOjE3NjUzMjE0NTZ9.obOcf9rK86hhrf4Xqq_4MvKoM20qKICNI6TXfblsKwU',
          },
          body: jsonEncode(payload),
        );

        print('✅ Response Status: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');

        final decoded = jsonDecode(response.body);
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            decoded['success'] == true) {
          await collectionProvider.createCollectionEvent(
            farmerId: authProvider.currentUser!.id,
            species: _speciesController.text,
            latitude: _latitude!,
            longitude: _longitude!,
            imagePaths: _images.map((f) => f.path).toList(),
            weight: double.tryParse(_weightController.text),
            moisture: double.tryParse(_moistureController.text),
            temperature: _temperature,
            humidity: _humidity,
            weatherCondition: _selectedWeatherCondition,
            commonName: _commonNameController.text.isNotEmpty ? _commonNameController.text : null,
            scientificName: _scientificNameController.text.isNotEmpty ? _scientificNameController.text : null,
            harvestMethod: _selectedHarvestMethod,
            partCollected: _selectedPartCollected,
            altitude: _altitude,
            latitudeAccuracy: _accuracy,
            longitudeAccuracy: _accuracy,
            locationName: _locationNameController.text.isNotEmpty ? _locationNameController.text : null,
            soilType: _selectedSoilType,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
          _showSuccessDialog(decoded['data']?['id'] ?? 'success');
        } else {
          print('❌ API Error: Status ${response.statusCode}');
          print('❌ Error Response: ${response.body}');
          throw Exception('API Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('💥 Exception caught: $e');
      await _offlineQueueBox.add(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Saved offline.')),
      );
      _showSuccessDialog('queued');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String eventId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
            ),
            const SizedBox(height: 20),
            Text(
              eventId == 'queued' ? 'Saved Offline!' : 'Submission Successful!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null)
              Text(
                'Location: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI widgets (camera section, location card, autocomplete fields, etc.) ---
  // Copy existing _buildLocationCard(), _buildCameraSection(), and Form fields
  // from your original code above without changes.

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final localeProvider = context.watch<LocaleProvider>();
    return WillPopScope(
      onWillPop: () async {
        // Allow normal back navigation
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localeProvider.translate('new_collection')),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _buildLocationCard(localeProvider),
              const SizedBox(height: 20),
              _buildCameraSection(localeProvider),
              const SizedBox(height: 20),

              // Autocomplete species
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _herbSpecies;
                  return _herbSpecies.where((species) =>
                      species.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  _speciesController.text = selection;
                  // Auto-fill common name and scientific name
                  if (_speciesDetails.containsKey(selection)) {
                    _commonNameController.text = _speciesDetails[selection]!['commonName']!;
                    _scientificNameController.text = _speciesDetails[selection]!['scientificName']!;
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate('species'),
                      prefixIcon: const Icon(Icons.local_florist),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please select a species';
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localeProvider.translate('weight'),
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'kg',
                  suffixIcon: Semantics(
                    label: _isListeningWeight
                        ? localeProvider.translate('a11y_voice_listening')
                        : '${localeProvider.translate('a11y_voice_input_for')} ${localeProvider.translate('weight')}',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _isListeningWeight ? Icons.mic : Icons.mic_none,
                        color: _isListeningWeight ? Colors.red : null,
                      ),
                      onPressed: () {
                        if (_isListeningWeight) _stopListening();
                        else _startListening(_weightController, 'weight');
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Moisture
              TextFormField(
                controller: _moistureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localeProvider.translate('moisture'),
                  prefixIcon: const Icon(Icons.water_drop),
                  suffixText: '%',
                  suffixIcon: Semantics(
                    label: _isListeningMoisture
                        ? localeProvider.translate('a11y_voice_listening')
                        : '${localeProvider.translate('a11y_voice_input_for')} ${localeProvider.translate('moisture')}',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _isListeningMoisture ? Icons.mic : Icons.mic_none,
                        color: _isListeningMoisture ? Colors.red : null,
                      ),
                      onPressed: () {
                        if (_isListeningMoisture) _stopListening();
                        else _startListening(_moistureController, 'moisture');
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Common Name
              TextFormField(
                controller: _commonNameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'सामान्य नाम' : 'Common Name',
                  prefixIcon: const Icon(Icons.grass),
                  hintText: localeProvider.isHindi ? 'उदा., अश्वगंधा' : 'e.g., Indian Ginseng',
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 16),

              // Scientific Name
              TextFormField(
                controller: _scientificNameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'वैज्ञानिक नाम' : 'Scientific Name',
                  prefixIcon: const Icon(Icons.science),
                  hintText: 'e.g., Withania somnifera',
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 16),

              // Harvest Method
              DropdownButtonFormField<String>(
                value: _selectedHarvestMethod,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'कटाई विधि' : 'Harvest Method',
                  prefixIcon: const Icon(Icons.cut),
                ),
                hint: Text(localeProvider.isHindi ? 'कटाई विधि चुनें' : 'Select Harvest Method'),
                items: _harvestMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(localeProvider.isHindi ? _harvestMethodsHindi[method]! : method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHarvestMethod = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Part Collected
              DropdownButtonFormField<String>(
                value: _selectedPartCollected,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'संग्रहित भाग' : 'Part Collected',
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                hint: Text(localeProvider.isHindi ? 'संग्रहित भाग चुनें' : 'Select Part Collected'),
                items: _partCollectedOptions.map((part) {
                  return DropdownMenuItem<String>(
                    value: part,
                    child: Text(localeProvider.isHindi ? _partCollectedHindi[part]! : part),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPartCollected = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Location Name
              TextFormField(
                controller: _locationNameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'स्थान का नाम' : 'Location Name',
                  prefixIcon: const Icon(Icons.location_city),
                  hintText: localeProvider.isHindi ? 'उदा., गांव का नाम, फार्म का नाम' : 'e.g., Village name, Farm name',
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 16),

              // Soil Type
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'मिट्टी प्रकार' : 'Soil Type',
                  prefixIcon: const Icon(Icons.landscape),
                ),
                hint: Text(localeProvider.isHindi ? 'मिट्टी प्रकार चुनें' : 'Select Soil Type'),
                items: _soilTypes.map((soil) {
                  return DropdownMenuItem<String>(
                    value: soil,
                    child: Text(localeProvider.isHindi ? _soilTypesHindi[soil]! : soil),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSoilType = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: localeProvider.isHindi ? 'टिप्पणियां' : 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  hintText: localeProvider.isHindi ? 'अतिरिक्त टिप्पणियां या टिप्पणी' : 'Additional observations or remarks',
                  alignLabelWithHint: true,
                  suffixIcon: Semantics(
                    label: _isListeningNotes
                        ? localeProvider.translate('a11y_voice_listening')
                        : '${localeProvider.translate('a11y_voice_input_for')} ${localeProvider.isHindi ? "टिप्पणियां" : "Notes"}',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _isListeningNotes ? Icons.mic : Icons.mic_none,
                        color: _isListeningNotes ? Colors.red : null,
                      ),
                      onPressed: () {
                        if (_isListeningNotes) _stopListening();
                        else _startListening(_notesController, 'notes');
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Weather info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          localeProvider.isHindi ? 'मौसम डेटा' : 'Weather Data',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingWeather)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Semantics(
                            label: localeProvider.translate('a11y_refresh_weather'),
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _getWeatherData,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_temperature != null && _humidity != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getWeatherIcon(_selectedWeatherCondition ?? 'Sunny'),
                            size: 20,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localeProvider.isHindi
                                ? 'मौसम स्थिति : ${_selectedWeatherCondition ?? "अज्ञात"}'
                                : 'Weather Condition : ${_selectedWeatherCondition ?? "Unknown"}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.thermostat, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            localeProvider.isHindi
                                ? 'तापमान : ${_temperature!.toStringAsFixed(1)}°C'
                                : 'Temperature : ${_temperature!.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.water_drop, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            localeProvider.isHindi
                                ? 'आर्द्रता : ${_humidity!.toStringAsFixed(0)}%'
                                : 'Humidity : ${_humidity!.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ] else if (!_isLoadingWeather) ...[
                      Text(
                        localeProvider.isHindi
                            ? 'मौसम डेटा उपलब्ध नहीं है'
                            : 'Weather data not available',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  localeProvider.translate('submit'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Sunny':
        return Icons.wb_sunny;
      case 'Clear Night':
        return Icons.nightlight_round;
      case 'Cloudy':
        return Icons.cloud;
      case 'Partly Cloudy':
        return Icons.wb_cloudy;
      case 'Rainy':
        return Icons.umbrella;
      case 'Drizzle':
        return Icons.grain;
      case 'Foggy':
        return Icons.foggy;
      case 'Snowy':
        return Icons.ac_unit;
      case 'Stormy':
        return Icons.thunderstorm;
      case 'Windy':
        return Icons.air;
      case 'Humid':
        return Icons.water_drop;
      default:
        return Icons.wb_cloudy;
    }
  }

// Copy your original _buildLocationCard() and _buildCameraSection() functions here

  Widget _buildLocationCard(LocaleProvider localeProvider) {
    bool hasLocation = _latitude != null && _longitude != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localeProvider.translate('gps_location'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (_isLoadingLocation)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Semantics(
                    label: localeProvider.translate('a11y_refresh_location'),
                    button: true,
                    child: IconButton(icon: const Icon(Icons.refresh), onPressed: _getCurrentLocation),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasLocation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingLocation ? 'Acquiring...' : 'Location Captured',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, color: AppTheme.success),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.my_location, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          if (_altitude != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.terrain, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Altitude: ${_altitude!.toStringAsFixed(1)} m',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                          if (_accuracy != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.gps_fixed, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Accuracy: ${_accuracy!.toStringAsFixed(1)} m',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.location_off, color: AppTheme.warning),
                    SizedBox(width: 12),
                    Expanded(child: Text('Acquiring GPS location...', style: TextStyle(color: AppTheme.warning))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection(LocaleProvider localeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeProvider.translate('capture_image'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final file = _images[index];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.red),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Semantics(
                            label: '${localeProvider.translate('a11y_delete_image')} ${index + 1}',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _images.removeAt(index);
                                });
                              },
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(localeProvider.translate('capture_image')),
            ),
            const SizedBox(height: 4),
            // if (_images.isEmpty)
            //   Text(
            //     'You can capture up to 3 images. Images are stored offline if internet is not available.',
            //     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            //   ),
          ],
        ),
      ),
    );
  }

}
