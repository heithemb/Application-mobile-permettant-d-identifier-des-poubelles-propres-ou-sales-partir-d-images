import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:twise/CameraScreen.dart';

import 'PreviewScreen.dart';
import 'homePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes:{
        '/':(context)=>homePage(),
        '/try':(context)=>CameraScreen(),
        '/preview':(context)=>PreviewScreen(imagePath:''),
      },
    );
  }
}
