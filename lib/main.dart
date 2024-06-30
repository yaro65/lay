import 'package:flutter/material.dart';
import 'package:lay/pdffiles.dart';
import 'firstpage.dart';
import 'thirdpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.grey[800],
        hintColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    Firstpage(),
    Thirdpage(),
    PdfListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 30,
              color: Colors.white,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/ic_launcher.jpeg',
                    height: 40.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Générer un PDF',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Signer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_present),
            label: 'Afficher les PDF',
          ),
        ],
      ),
    );
  }
}
