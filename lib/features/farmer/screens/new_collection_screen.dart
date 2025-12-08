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
import '../../auth/providers/auth_provider.dart';
import '../providers/collection_provider.dart';

class NewCollectionScreen extends StatefulWidget {
  const NewCollectionScreen({super.key});

  @override
  State<NewCollectionScreen> createState() => _NewCollectionScreenState();
}

class _NewCollectionScreenState extends State<NewCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _weightController = TextEditingController();
  final _moistureController = TextEditingController();

  final List<File> _images = [];
  double? _latitude;
  double? _longitude;
  double? _temperature;
  double? _humidity;
  bool _isLoadingLocation = false;
  bool _isLoadingWeather = false;
  bool _isSubmitting = false;

  late stt.SpeechToText _speech;
  bool _isListeningSpecies = false;
  bool _isListeningWeight = false;
  bool _isListeningMoisture = false;

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

  late Box _offlineQueueBox;
  late Box _cacheBox;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initHive();
    _getCurrentLocation();
    _listenConnectivity();
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
    }
    if (_cacheBox.containsKey('weather')) {
      final weather = _cacheBox.get('weather');
      _temperature = weather['temperature'];
      _humidity = weather['humidity'];
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _weightController.dispose();
    _moistureController.dispose();
    super.dispose();
  }

  Future<void> _startListening(TextEditingController controller, String field) async {
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() {
      _isListeningSpecies = field == 'species';
      _isListeningWeight = field == 'weight';
      _isListeningMoisture = field == 'moisture';
    });

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
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListeningSpecies = false;
      _isListeningWeight = false;
      _isListeningMoisture = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _cacheBox.put('location', {'latitude': _latitude, 'longitude': _longitude});
      await _getWeatherData();
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

      if (weatherData != null) {
        setState(() {
          _temperature = weatherData['temperature'];
          _humidity = weatherData['humidity'];
        });
        _cacheBox.put('weather', {'temperature': _temperature, 'humidity': _humidity});
      }
    } catch (_) {}

    setState(() {
      _isLoadingWeather = false;
    });
  }

  Future<void> _captureImage() async {
    try {
      if (_images.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 images allowed')),
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 70,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
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
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MTQzMDA0LCJleHAiOjE3NjUyMjk0MDR9.O_shrDHZfmHVj4r5SDU5LMN0vXnHdSia4viUdeA2GXY',
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
      "location":
      "Lat: ${_latitude!.toStringAsFixed(6)}, Lon: ${_longitude!.toStringAsFixed(6)}",
      "imagePaths": _images.map((f) => f.path).toList(),
      "temperature": _temperature,
      "humidity": _humidity,
      "moisture": double.tryParse(_moistureController.text),
    };

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
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MTQzMDA0LCJleHAiOjE3NjUyMjk0MDR9.O_shrDHZfmHVj4r5SDU5LMN0vXnHdSia4viUdeA2GXY',
          },
          body: jsonEncode(payload),
        );

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
          );
          _showSuccessDialog(decoded['data']?['id'] ?? 'success');
        } else {
          throw Exception('API Error: ${response.statusCode}');
        }
      }
    } catch (e) {
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
    final localeProvider = context.watch<LocaleProvider>();
    return Scaffold(
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
                  suffixIcon: IconButton(
                    icon: Icon(_isListeningWeight ? Icons.mic : Icons.mic_none),
                    onPressed: () {
                      if (_isListeningWeight) _stopListening();
                      else _startListening(_weightController, 'weight');
                    },
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
                  suffixIcon: IconButton(
                    icon: Icon(_isListeningMoisture ? Icons.mic : Icons.mic_none),
                    onPressed: () {
                      if (_isListeningMoisture) _stopListening();
                      else _startListening(_moistureController, 'moisture');
                    },
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
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_temperature != null && _humidity != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.thermostat, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            localeProvider.isHindi
                                ? 'तापमान: ${_temperature!.toStringAsFixed(1)}°C'
                                : 'Temperature: ${_temperature!.toStringAsFixed(1)}°C',
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
                                ? 'आर्द्रता: ${_humidity!.toStringAsFixed(0)}%'
                                : 'Humidity: ${_humidity!.toStringAsFixed(0)}%',
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
    );
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
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _getCurrentLocation),
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
                          Text(
                            '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          // if (_cacheBox.containsKey('location'))
                          //   Text(
                          //     '(Using cached location)',
                          //     style: const TextStyle(fontSize: 10, color: Colors.grey),
                          //   ),
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
