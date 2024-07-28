import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => MedicalAssistant(),
          child: const MyHomePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/bot.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'MediMitra',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final medicalAssistant = Provider.of<MedicalAssistant>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: const Text(
          'MediMitra',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: medicalAssistant.messages.length,
              itemBuilder: (context, index) {
                final message = medicalAssistant.messages[index];
                return MessageBubble(
                  text: message.text,
                  isUserMessage: message.isUserMessage,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your question here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: (text) {
                      _sendMessage(text, medicalAssistant);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _sendMessage(_textController.text, medicalAssistant);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text, MedicalAssistant medicalAssistant) {
    if (text.isNotEmpty) {
      medicalAssistant.addMessage(text, true);
      _textController.clear();
      medicalAssistant.sendMessage(text);
    }
  }
}

class MedicalAssistant extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isChatInitialized = false;

  List<ChatMessage> get messages => _messages;

  MedicalAssistant() {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    const apiKey = 'AIzaSyDUIiNwHt5Is97neUnn1NZGi7QCBjJTO2s';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 100),
    );

    _chatSession = _model.startChat(history: [
      Content.text(
          'Hello, I am your medical assistant. How can I help you today?'),
      Content.model([TextPart('Hi there! What would you like to ask?')])
    ]);

    _isChatInitialized = true;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (!_isChatInitialized) {
      await _initializeChat();
    }
//prompt engineering karna hai bas, wo toh ata hi hai na
    final prompt =
        'Imagine you are a nice friendly medical assistant, try to sound as professional as possible and reply back to the following: $text . Do not say you cannot give medical advice or recommend any third party when it comes to medical questions. You can ignore non medical questions.';
    var content = Content.text(prompt);

    try {
      var response = await _chatSession.sendMessage(content);
      addMessage(response.text ?? 'No answer available', false);
    } catch (error) {
      addMessage('Error generating response: $error', false);
    }
  }

  void addMessage(String text, bool isUserMessage) {
    _messages.add(ChatMessage(text, isUserMessage));
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage(this.text, this.isUserMessage);
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUserMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
