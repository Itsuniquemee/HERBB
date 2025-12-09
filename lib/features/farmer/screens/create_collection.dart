import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  bool _isSubmitting = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  TextEditingController? _activeController;

  Timer? _speechTimeout; // For auto-stop after inactivity

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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _weightController.dispose();
    _moistureController.dispose();
    _speechTimeout?.cancel();
    super.dispose();
  }

  // ------------------ Location & Weather ------------------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      final weatherService = WeatherService();
      final weatherData = await weatherService.getWeatherDataFree(
          latitude: _latitude!, longitude: _longitude!);
      if (weatherData != null) {
        setState(() {
          _temperature = weatherData['temperature'];
          _humidity = weatherData['humidity'];
        });
      }
    }

    if (mounted) setState(() => _isLoadingLocation = false);
  }

  // ------------------ Image Capture ------------------
  Future<void> _captureImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = DateTime.now().millisecondsSinceEpoch.toString() +
            "_" +
            pickedFile.name;
        final savedFile = await File(pickedFile.path)
            .copy('${appDir.path}/$fileName');

        if (!mounted) return;
        setState(() => _images.add(savedFile));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  // ------------------ Speech Recognition ------------------
  void _startListening(TextEditingController controller) async {
    _activeController = controller;

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          _stopListening();
        }
      },
      onError: (val) {
        _stopListening();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${val.errorMsg}')),
        );
      },
    );

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (val) {
          setState(() {
            _activeController!.text = val.recognizedWords;
          });

          // Reset inactivity timer
          _speechTimeout?.cancel();
          _speechTimeout = Timer(const Duration(seconds: 5), () {
            _stopListening();
          });
        },
        listenMode: stt.ListenMode.dictation,
      );

      // Start a safety timer in case no speech is detected
      _speechTimeout?.cancel();
      _speechTimeout = Timer(const Duration(seconds: 5), () {
        _stopListening();
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    _speechTimeout?.cancel();
    setState(() => _isListening = false);
  }

  // ------------------ Submit ------------------
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

    try {
      final payload = {
        "species": _speciesController.text,
        "quantity": double.tryParse(_weightController.text) ?? 0,
        "unit": "kg",
        "harvestDate": DateTime.now().toIso8601String().split('T')[0],
        "latitude": _latitude!.toString(),
        "longitude": _longitude!.toString(),
        "location":
        "Lat: ${_latitude!.toStringAsFixed(6)}, Lon: ${_longitude!.toStringAsFixed(6)}"
      };

      final response = await http.post(
        Uri.parse(
            'https://herbal-trace-production.up.railway.app/api/v1/collections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
          'Bearer YOUR_TOKEN_HERE', // Replace with dynamic token if needed
        },
        body: jsonEncode(payload),
      );

      final decoded = jsonDecode(response.body);
      print('Response Body: ${response.body}');

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

        final eventId = decoded['data']?['id'] ?? 'success';
        if (!mounted) return;
        _showSuccessDialog(eventId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Submission failed: ${response.statusCode} ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
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
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Submission Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Event ID: ${eventId.length >= 8 ? eventId.substring(0, 8) : eventId}',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
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

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(localeProvider.translate('new_collection'))),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  _buildSpeciesDropdown(),
                  const SizedBox(height: 16),
                  _buildSpeechTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      localeProvider: localeProvider),
                  const SizedBox(height: 16),
                  _buildSpeechTextField(
                      controller: _moistureController,
                      label: 'Moisture (%)',
                      localeProvider: localeProvider),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      localeProvider.translate('submit'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildMicOverlay(),
        ],
      ),
    );
  }

  // ------------------ Custom Widgets ------------------
  Widget _buildSpeciesDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _speciesController.text.isNotEmpty
            ? _speciesController.text
            : null,
        decoration: const InputDecoration(border: InputBorder.none),
        items: _herbSpecies
            .map((species) => DropdownMenuItem(
            value: species,
            child: Text(species,
                style: const TextStyle(fontWeight: FontWeight.w500))))
            .toList(),
        onChanged: (value) {
          if (value != null) _speciesController.text = value;
        },
        validator: (value) =>
        (value == null || value.isEmpty) ? 'Required' : null,
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildSpeechTextField({
    required TextEditingController controller,
    required String label,
    required LocaleProvider localeProvider,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          onPressed: () {
            if (_isListening) {
              _stopListening();
            } else {
              _startListening(controller);
            }
          },
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
      (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildMicOverlay() {
    if (!_isListening) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: MediaQuery.of(context).size.width / 2 - 40,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildLocationCard(LocaleProvider localeProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(localeProvider.translate('gps_weather'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (_isLoadingLocation)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                    onPressed: _getCurrentLocation),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoTile(
                  icon: Icons.location_on,
                  title: 'Lat',
                  value: _latitude?.toStringAsFixed(6) ?? '--'),
              _buildInfoTile(
                  icon: Icons.location_on,
                  title: 'Lon',
                  value: _longitude?.toStringAsFixed(6) ?? '--'),
              _buildInfoTile(
                  icon: Icons.thermostat,
                  title: 'Temp',
                  value: _temperature != null
                      ? '${_temperature!.toStringAsFixed(1)}°C'
                      : '--'),
              _buildInfoTile(
                  icon: Icons.water_drop,
                  title: 'Humidity',
                  value:
                  _humidity != null ? '${_humidity!.toStringAsFixed(1)}%' : '--'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon, required String title, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCameraSection(LocaleProvider localeProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(localeProvider.translate('capture_image'),
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final file = _images[index];
                  final fileExists = file.existsSync();
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                        child: fileExists
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(file, fit: BoxFit.cover),
                        )
                            : const Icon(Icons.broken_image, size: 40),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          if (_images.length < 3)
            OutlinedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                  '${_images.isEmpty ? 'Capture' : 'Add Another'} Image (${_images.length}/3)'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen)),
            ),
        ]),
      ),
    );
  }
}
