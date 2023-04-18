import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VoiceChatGPT(),
    );
  }
}

class VoiceChatGPT extends StatefulWidget {
  @override
  _VoiceChatGPTState createState() => _VoiceChatGPTState();
}

class _VoiceChatGPTState extends State<VoiceChatGPT> {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  String _gptResponseText = '';
  bool _isListening = false;
  bool _showDots = false;
  String _currentLocale = '';

  Future<String> _getLocale() async {
    final systemLocale = await ui.window.locale;
    return systemLocale.languageCode;
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
        debugLogging: true,
        finalTimeout: Duration(milliseconds: 800),
      );

      if (available) {
        _currentLocale = await _getLocale(); // 获取当前设备的语言设置
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => _getChatGPTResponse(val.recognizedWords),
          listenFor: Duration(seconds: 10),
          localeId: _currentLocale, // 使用当前语言设置
          cancelOnError: true,
          partialResults: true,
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

void _getChatGPTResponse(String text) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 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',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': text,
          }
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      String chatGPTResponse = json.decode(response.body)['choices'][0]['message']['content'];
      _flutterTts.speak(chatGPTResponse);
      setState(() {
        _gptResponseText = chatGPTResponse;
      });
    } else {
      print('Failed to get ChatGPT response');
    }
  } catch (e) {
    print('Error while getting ChatGPT response: $e');
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: () => _startListening(),
      child: Stack(
        children: [
          ListView(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _gptResponseText,
                  style: TextStyle(fontSize: 30, color: Colors.lightGreen),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (_showDots)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '...',
                  style: TextStyle(fontSize: 30, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

}

