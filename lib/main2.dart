import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get the front camera from the list of available cameras.
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: CameraFrameSender(
        // Pass the front camera to the CameraFrameSender widget.
        camera: frontCamera,
      ),
    ),
  );
}

class CameraFrameSender extends StatefulWidget {
  const CameraFrameSender({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  _CameraFrameSenderState createState() => _CameraFrameSenderState();
}

class _CameraFrameSenderState extends State<CameraFrameSender> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();

    // Start a timer to capture frames every 1 second.
    
    // _timer = Timer.periodic(Duration(seconds: 1), _captureAndSendFrame);
  }

  @override
  void dispose() {
    // Dispose of the controller and cancel the timer when the widget is disposed.
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _captureAndSendFrame() async {
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture and get the frame as bytes.
      
      final XFile image = await _controller.takePicture();

      // Read the image file and send it to the server.
      final Uint8List imageBytes = await File(image.path).readAsBytes();
      print(imageBytes);

      var headersList = {
        'Accept': '*/*'
        };
        var url = Uri.parse('http://192.168.10.64:5000/analyze_frame');

        // var body = {
        
        // };

        var req = http.MultipartRequest('POST', url);
        req.headers.addAll(headersList);
        req.files.add(await http.MultipartFile.fromBytes('image', imageBytes));
        // req.fields.addAll(body);

        var res = await req.send();
        final resBody = await res.stream.bytesToString();

        if (res.statusCode >= 200 && res.statusCode < 300) {
          print(resBody);
          print("got_the_result");
        }
        else {
          print(res.reasonPhrase);
          print("getting error.....");
        }
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Camera Frames to Server')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: _captureAndSendFrame,
            child: Text('Take Picture'),
          ),
        ],
      ),
    );
  }
}