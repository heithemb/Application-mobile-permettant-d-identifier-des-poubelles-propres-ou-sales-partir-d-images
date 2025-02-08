import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
class PreviewScreen extends StatelessWidget {
  final String imagePath;

  PreviewScreen({required this.imagePath});

  Future<void> _sendImage(BuildContext context) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.216:8000/predict/'),
    );

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imagePath,
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      String classification = jsonResponse['class'];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Résultat'),
            content: Text('L\'image est classée comme: $classification'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erreur'),
            content: Text('Erreur lors de l\'envoi de l\'image'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prévisualisation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<Uint8List>(
              future: _loadImage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Image.memory(snapshot.data!);
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Envoyer'),
              onPressed: () => _sendImage(context),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _loadImage() async {
    if (kIsWeb) {
      // For web, read the file as bytes
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      return bytes;
    } else {
      // For mobile, read the file as bytes
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      return bytes;
    }
  }
}