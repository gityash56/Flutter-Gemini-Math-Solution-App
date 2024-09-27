import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Complete Math Solving app using gemini api


void main() {
  // API KEY
  Gemini.init(apiKey: 'Your Api key');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Math Solving'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? imageQuestion;
  String? answer;
  bool isLoading = false;

  // Function to pick image from the gallery
  void selectImageFromGallery() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      cropImage(image);
    }
  }

  // Function to pick image from the camera
  void captureImageFromCamera() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      cropImage(image);
    }
  }

  // Function to clear all data (image and answer)
  void clearAllData() {
    setState(() {
      imageQuestion = null;
      answer = null;
      isLoading = false;
    });
  }

  // Function to crop image
  void cropImage(XFile image) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false, // Allows free cropping
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        imageQuestion = XFile(croppedFile.path);
        isLoading = true;
      });

      // Process image with Gemini
      processImage();
    }
  }

  // Function to process the image with Gemini API
  void processImage() async {
    final gemini = Gemini.instance;
    gemini.textAndImage(
      text: "Can you solve this equation?",
      images: [await imageQuestion!.readAsBytes()],
    ).then((value) {
      setState(() {
        answer = value?.content?.parts?.last.text ?? '';
        isLoading = false;
      });
    }).catchError((e) {
      log('textAndImageInput', error: e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b1c1c),
      appBar: AppBar(
        backgroundColor: const Color(0xff1b1c1c),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear , color: Colors.blue,),
            onPressed: clearAllData, // Clears all data
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              height: imageQuestion == null ? 300 : null,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Color(0xff242c2c)),
              child: imageQuestion == null
                  ? const Text(
                'No Image Selected',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              )
                  : Image.file(
                File(imageQuestion!.path),
                fit: BoxFit.fill,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(

                  onPressed: selectImageFromGallery,
                  child: const Text(
                    'Select from Gallery',
                    style: TextStyle(color: Colors.green, fontSize: 20.0),
                  ),
                ),
                const SizedBox(width: 10),
                Wrap( children: [
                  ElevatedButton(

                    onPressed: captureImageFromCamera,
                    child: const Text(
                      'Capture from Camera',
                      style: TextStyle(color: Colors.pink, fontSize: 20.0),
                    ),
                  ),

                ],

                )


              ],
            ),

            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator(color: Colors.blue)
                : answer != null
                ? Text(
              answer!,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18.0),
              textAlign: TextAlign.start,
            )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
