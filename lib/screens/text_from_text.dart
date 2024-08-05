import 'package:flutter/material.dart';
import 'package:gembot/providers/gemini_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // Import the flutter_tts package

class TextFromVoiceScreen extends StatefulWidget {
  const TextFromVoiceScreen({super.key});

  @override
  _TextFromVoiceScreenState createState() => _TextFromVoiceScreenState();
}

class _TextFromVoiceScreenState extends State<TextFromVoiceScreen> {
  final TextEditingController _textController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts(); // Initialize FlutterTts

  bool _isListening = false;
  String _voiceInput = '';

  @override
  Widget build(BuildContext context) {
    final geminiProvider = Provider.of<GeminiProvider>(context);

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
                      onPressed: _listen,
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
              const SizedBox(height: 16),
              if (geminiProvider.response != null)
                ElevatedButton(
                  onPressed: () async {
                    await _flutterTts.speak(geminiProvider.response!);
                  },
                  child: const Text('Read'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceInput = val.recognizedWords;
              _textController.text = _voiceInput;
            });
            print('Recognized Words: $_voiceInput');
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
