import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 300,
          backgroundColor: Colors.red,
          centerTitle: true,
          title: const CircleAvatar(
            radius: 100,
            backgroundImage: NetworkImage('https://i.postimg.cc/QMYSkGhW/Gemini-Generated-Image-mqgujnmqgujnmqgu.jpg'),
          ),
        ),
        body: const Center(
          child: Text('Mustak has stolen our ideas.'),
        ),
        bottomNavigationBar: BottomNavigationBar(items: const[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile')
        ]),
      ),
    );
  }
}