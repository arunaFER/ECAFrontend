import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';


void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  File? imageFile;
  String? message;

  FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {

    const Color customColor = Color.fromRGBO(204, 198, 198, 1.0); // R, G, B, Alpha (opacity)

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECA'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0, bottom: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageFile != null)
                  Container(
                    width: 200,
                    height: 300,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: customColor,
                      image: DecorationImage(
                          image: FileImage(imageFile!),
                          fit: BoxFit.cover
                      ),
                      border: Border.all(width: 1, color: Colors.black12),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  )
                else
                  Container(
                    width: 200,
                    height: 300,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: customColor,
                      border: Border.all(width: 1, color: Colors.black12),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Text(
                      'Image should appear here',
                      style: TextStyle(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 80),
            Container(
              constraints: BoxConstraints(maxWidth: 300), // Set your desired maximum width here
              child: Text(
                message ?? 'Hello World',
                style: TextStyle(fontSize: 25),
              ),
            ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: ()=> getImage(source: ImageSource.camera),
                      child: const Text('Take Image', style: TextStyle(fontSize: 18))
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void getImage({required ImageSource source}) async{

    final  file = await ImagePicker().pickImage(source: source);

    if (file?.path != null){
      setState(() {
        imageFile = File(file!.path);
      });
    }

    // Upload the captured image
    uploadImage(imageFile!);
  }

  void uploadImage(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:3000/predict"),
      );

      // Attach the image file to the request
      request.files.add(
        http.MultipartFile(
          'file', // The key "file" should match the backend's expectation
          image.readAsBytes().asStream(),
          image.lengthSync(),
          filename: 'image.jpg', // Set the filename to "image.jpg"
        ),
      );

      // Send the request and get the response
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseString = await response.stream.bytesToString();
        String extractedCaption = extractCaptionFromResponse(responseString);

        setState(() {
          message = extractedCaption;
        });

        print(message);

        await flutterTts.setLanguage("en-US");
        await flutterTts.speak(message!);

        print(responseString);
      } else {
        setState(() {
          message = 'API Request failed';
        });

        print('API Request failed with status ${response.statusCode}');
        print('API Request failed with status ${response.headers}');

        await flutterTts.setLanguage("en-US");
        await flutterTts.speak(message!);
      }
    } catch (e) {
      setState(() {
        message = 'Error uploading image';
      });

      await flutterTts.setLanguage("en-US");
      await flutterTts.speak(message!);

      print('Error uploading image: $e');
    }
  }


  String extractCaptionFromResponse(String response) {
    try {
      final Map<String, dynamic> jsonResponse = json.decode(response);
      final List<dynamic> captionList = jsonResponse['caption'];

      if (captionList.isNotEmpty) {
        final String caption = captionList[0];
        return caption;
      } else {
        return 'No caption available';
      }
    } catch (e) {
      return 'Error parsing response';
    }
  }


}