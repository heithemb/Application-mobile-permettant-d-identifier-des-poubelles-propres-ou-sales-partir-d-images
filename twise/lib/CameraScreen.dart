import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isLoading = false;
  String? _predictionResult;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> captureAndSendImage() async {
    if (!_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      XFile file = await _controller!.takePicture();
      Uint8List imageBytes = await file.readAsBytes();  

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8002/predict/'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'captured_image.jpg',  
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          if(decodedResponse['predicted_class']==0){
          _predictionResult = "Predicted Class: Clean";}else {_predictionResult = "Predicted Class: Dirty";
          }
        });
      } else {
        setState(() {
          print("here2");
          _predictionResult = "Error: ${decodedResponse['error']}";
        });
      }
    } catch (e) {
      setState(() {
        print("here");
        _predictionResult = "Error: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture & Predict Image')),
      body: Container(
    decoration: BoxDecoration(
    image: DecorationImage(
    image: AssetImage('assets/38700f4d1b8aa941d57d6de55ab60742.jpg'), 
    fit: BoxFit.cover, // Cela permet de remplir tout l'écran avec l'image
    ),
    ),
    child:Column(
        children: [
          Expanded(  
            child: _controller == null || !_controller!.value.isInitialized
                ? Container(color: Colors.black)
                : AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : captureAndSendImage,
            child: _isLoading ? CircularProgressIndicator() : Text('Capture & Predict'),
          ),
          SizedBox(height: 20),
          if (_predictionResult != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                _predictionResult!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),)

    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
