import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DisplayScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String semester;
  final PlatformFile file;

  const DisplayScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.semester,
    required this.file,
  });

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  String ocrText = "Extracting text...";
  final FlutterTts flutterTts = FlutterTts();

  bool isPlaying = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        isPaused = false;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        isPlaying = false;
        isPaused = false;
      });
    });

    _performOCR();
  }

  Future<void> _performOCR() async {
    final filePath = widget.file.path;
    if (filePath == null || !File(filePath).existsSync()) {
      setState(() => ocrText = "File not found");
      return;
    }

    final extension = filePath.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      try {
        final bytes = File(filePath).readAsBytesSync();
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        final String text = PdfTextExtractor(document).extractText();
        print("Extracted PDF Text: $text"); // Debug print

        document.dispose();

        if (text.trim().isEmpty) {
          setState(() => ocrText = "No text found in PDF");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No selectable text found in PDF')),
          );
        } else {
          setState(() => ocrText = text);
        }
      } catch (e) {
        setState(() => ocrText = "Failed to extract text from PDF");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to extract text from PDF')),
        );
      }
    } else {
      // Image OCR
      final inputImage = InputImage.fromFilePath(filePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      setState(
        () => ocrText = recognizedText.text.isEmpty
            ? "No text found in image"
            : recognizedText.text,
      );
      await textRecognizer.close();
    }
  }

  Future<void> _speak() async {
    if (ocrText.trim().isEmpty ||
        ocrText == "No text found in PDF" ||
        ocrText == "Failed to extract text from PDF" ||
        ocrText == "No text found in image") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text available to read aloud')),
      );
      return;
    }

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    String textToSpeak = ocrText.length > 500
        ? ocrText.substring(0, 500) + '...'
        : ocrText;

    await flutterTts.speak(textToSpeak);

    setState(() {
      isPlaying = true;
      isPaused = false;
    });
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) {
      setState(() {
        isPaused = true;
        isPlaying = false;
      });
    }
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      setState(() {
        isPlaying = false;
        isPaused = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadAloudEnabled =
        !(ocrText.trim().isEmpty ||
            ocrText == "No text found in PDF" ||
            ocrText == "Failed to extract text from PDF" ||
            ocrText == "No text found in image");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Student Data",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${widget.name}"),
            Text("Email: ${widget.email}"),
            Text("Phone: ${widget.phone}"),
            Text("Semester: ${widget.semester}"),
            const SizedBox(height: 16),
            const Text(
              "Document Content:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    ocrText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(isPlaying ? Icons.pause : Icons.volume_up),
                  label: Text(isPlaying ? "Pause" : "Read Aloud"),
                  onPressed: isReadAloudEnabled
                      ? () {
                          if (isPlaying) {
                            _pause();
                          } else {
                            // If paused or stopped, start speaking again from start
                            _speak();
                          }
                        }
                      : null,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                  onPressed: isReadAloudEnabled ? _stop : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
