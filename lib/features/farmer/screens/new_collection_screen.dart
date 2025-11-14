import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/location_service.dart';
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
  final _notesController = TextEditingController();

  String? _selectedQuality;
  List<File> _images = [];
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

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

  final List<String> _qualityOptions = [
    'Premium',
    'Grade A',
    'Grade B',
    'Standard'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _weightController.dispose();
    _moistureController.dispose();
    _notesController.dispose();
    super.dispose();
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
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _captureImage() async {
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
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
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

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = context.read<AuthProvider>();
    final collectionProvider = context.read<CollectionProvider>();

    try {
      final eventId = await collectionProvider.createCollectionEvent(
        farmerId: authProvider.currentUser!.id,
        species: _speciesController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        imagePaths: _images.map((f) => f.path).toList(),
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        moisture: _moistureController.text.isNotEmpty
            ? double.tryParse(_moistureController.text)
            : null,
        quality: _selectedQuality,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      // Show success screen
      _showSuccessDialog(eventId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Event ID: ${eventId.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_latitude != null && _longitude != null)
              Text(
                'Location: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to dashboard
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

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
              // GPS Location Card
              _buildLocationCard(localeProvider),

              const SizedBox(height: 20),

              // Camera Section
              _buildCameraSection(localeProvider),

              const SizedBox(height: 20),

              // Species Selection
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _herbSpecies;
                  }
                  return _herbSpecies.where((species) => species
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  _speciesController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  _speciesController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate('species'),
                      prefixIcon: const Icon(Icons.local_florist),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a species';
                      }
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
                ),
              ),

              const SizedBox(height: 16),

              // Quality Dropdown
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: InputDecoration(
                  labelText: localeProvider.translate('quality'),
                  prefixIcon: const Icon(Icons.star),
                ),
                items: _qualityOptions.map((quality) {
                  return DropdownMenuItem(
                    value: quality,
                    child: Text(quality),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuality = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: localeProvider.translate('notes'),
                  prefixIcon: const Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }

  Widget _buildLocationCard(LocaleProvider localeProvider) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getCurrentLocation,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null)
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
                          const Text(
                            'Location Captured',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.success,
                            ),
                          ),
                          Text(
                            '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
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
                child: const Row(
                  children: [
                    Icon(Icons.location_off, color: AppTheme.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Acquiring GPS location...',
                        style: TextStyle(color: AppTheme.warning),
                      ),
                    ),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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
                  side: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
