import 'package:flutter/material.dart';
import 'package:gembot/providers/gemini_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // Import the speech_to_text package

class TextFromVoiceScreen extends StatefulWidget {
  const TextFromVoiceScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TextFromVoiceScreenState createState() => _TextFromVoiceScreenState();
}

class _TextFromVoiceScreenState extends State<TextFromVoiceScreen> {
  // Declare TextEditingController and SpeechToText instances
  final TextEditingController _textController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false; // Track whether the app is listening
  String _voiceInput = ''; // Store the recognized voice input

  @override
  Widget build(BuildContext context) {
    final geminiProvider = Provider.of<GeminiProvider>(context);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        geminiProvider.reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Input to Text Output ✨'),
          foregroundColor: Colors.black,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 9,
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your prompt or use the mic...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed:
                          _listen, // Start listening when the button is pressed
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        geminiProvider.generateContentFromText(
                          prompt: _textController.text,
                        );
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              geminiProvider.isLoading
                  ? const CircularProgressIndicator()
                  : geminiProvider.response != null
                      ? Expanded(
                          child: SingleChildScrollView(
                            child: Text(geminiProvider.response!),
                          ),
                        )
                      : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  /// Method to handle voice input
  void _listen() async {
    if (!_isListening) {
      // Check if the SpeechToText instance is available and not listening
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        // Start listening
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceInput = val.recognizedWords;
              _textController.text =
                  _voiceInput; // Set the recognized words to the text field
            });
            print(
                'Recognized Words: $_voiceInput'); // Print the recognized words to the terminal
          },
        );
      }
    } else {
      // Stop listening
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
