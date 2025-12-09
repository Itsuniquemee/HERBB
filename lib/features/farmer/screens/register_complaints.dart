import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';

class ComplainPage extends StatefulWidget {
  const ComplainPage({super.key});

  @override
  State<ComplainPage> createState() => _ComplainPageState();
}

class _ComplainPageState extends State<ComplainPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  String? _selectedType;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        title: Text(
          localeProvider.isHindi ? "शिकायत दर्ज करें" : "Submit Complaint",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localeProvider.isHindi ? "हम आपकी मदद के लिए यहां हैं!" : "We're here to help!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  localeProvider.isHindi ? "कृपया नीचे अपनी शिकायत दर्ज करें।" : "Please submit your complaint below.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                _buildInput(localeProvider.isHindi ? "विषय" : "Subject", subjectController, localeProvider),

                /// Complaint Type Dropdown
                const SizedBox(height: 15),
                Text(
                  localeProvider.isHindi ? "शिकायत का प्रकार" : "Complaint Type",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text(localeProvider.isHindi ? "शिकायत का प्रकार चुनें" : "Select Complaint Type"),
                    items: (localeProvider.isHindi 
                      ? ["उत्पाद समस्या", "किसान समस्या", "वितरण समस्या", "ऐप समस्या", "अन्य"]
                      : ["Product Issue", "Farmer Issue", "Delivery Issue", "App Issue", "Other"]
                    ).map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val;
                      });
                    },
                  ),
                ),

                /// Complaint Message with Speech-to-Text
                const SizedBox(height: 15),
                Text(
                  localeProvider.isHindi ? "शिकायत विवरण" : "Complaint Description",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Stack(
                  children: [
                    TextFormField(
                      controller: messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: localeProvider.isHindi ? "अपनी शिकायत विस्तार से बताएं" : "Describe your complaint in detail",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localeProvider.isHindi ? "विवरण आवश्यक है" : "Description is required";
                        }
                        return null;
                      },
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _isListening ? Colors.red : AppTheme.primaryGreen,
                        child: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                          ),
                          onPressed: () => _listen(localeProvider),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Submit Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _showSuccessDialog(localeProvider);
                      }
                    },
                    child: Text(
                      localeProvider.isHindi ? "शिकायत दर्ज करें" : "Submit Complaint",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable input method
  Widget _buildInput(String label, TextEditingController controller, LocaleProvider localeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localeProvider.isHindi ? "$label आवश्यक है" : "$label is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Speech-to-Text function with locale support
  void _listen(LocaleProvider localeProvider) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        
        // Use Hindi locale if app is in Hindi mode, otherwise English
        String localeId = localeProvider.isHindi ? 'hi_IN' : 'en_US';
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              messageController.text = val.recognizedWords;
            });
          },
          localeId: localeId,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Success Popup
  void _showSuccessDialog(LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localeProvider.isHindi ? "शिकायत दर्ज की गई" : "Complaint Submitted"),
        content: Text(localeProvider.isHindi ? "धन्यवाद! हम जल्द ही आपसे संपर्क करेंगे।" : "Thank you! We will get back to you soon."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localeProvider.isHindi ? "ठीक है" : "OK",
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
