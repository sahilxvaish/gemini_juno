import 'dart:ffi';
import 'dart:io';


import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "JUNO");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFDBDB),Color(0xFFF4D6DF),Color(0xFFE9D1E3),Color(0xFFDECCE7), Color(0xFFD4C8EC)])),),
        title: Center(child: const Text(
          "JUNO Here!",
          style: TextStyle(
            color: Colors.black54,
            decoration: TextDecoration.overline,
          ),
        ),
        ),

      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI(){
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(onPressed: _sendMediaMessage, icon:const Icon(Icons.image))
      ]),
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) {
   setState(() {
     messages = [chatMessage, ...messages];
   });
   try{
     String question = chatMessage.text;
     if(chatMessage.medias?.isNotEmpty ?? false) {
       // images = [
       //   File(chatMessage.medias!.first.url).readAsBytesSync(),
       // ];
     }
     gemini.streamGenerateContent(question).listen((event) {
       ChatMessage? lastMessage = messages.firstOrNull;
       if(lastMessage != null && lastMessage.user == geminiUser){
         lastMessage = messages.removeAt(0);
         String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
         lastMessage.text += response;
         setState(() {
           messages = [lastMessage!, ...messages];
         });
       }else{
         String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
         ChatMessage message = ChatMessage(user: geminiUser, createdAt: DateTime.now(), text: response);

         setState(() {
           messages = [message, ...messages];
         });
       }
     });
   } catch (e) {
     print(e);
   }
  }
  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(user: currentUser, createdAt: DateTime.now(), text: "Describe this picture?", medias: [
        ChatMedia(url: file.path, fileName: "", type: MediaType.image),
      ],
      );
      _sendMessage(chatMessage);
    }
  }
}
