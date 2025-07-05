import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'display_screen.dart';

class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _semester = '1st';
  PlatformFile? _pickedFile;

  // Permission request function
  Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<void> _startListening(TextEditingController controller) async {
    bool permissionGranted = await requestMicrophonePermission();
    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          controller.text = val.recognizedWords;
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition unavailable')),
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayScreen(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            semester: _semester,
            file: _pickedFile!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick a file')),
      );
    }
  }

  Widget _voiceTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.mic),
          onPressed: () => _startListening(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Info Form'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _voiceTextField("Name", _nameController),
                _voiceTextField("Email", _emailController),
                _voiceTextField("Phone", _phoneController),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _semester,
                  items: List.generate(
                    8,
                    (index) => DropdownMenuItem(
                      value: '${index + 1}st',
                      child: Text('${index + 1}st'),
                    ),
                  ),
                  onChanged: (val) => setState(() => _semester = val!),
                  decoration: const InputDecoration(labelText: 'Semester'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Document"),
                  onPressed: _pickFile,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
