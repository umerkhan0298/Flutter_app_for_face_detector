import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'fun.dart';
import 'dart:typed_data';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.firstWhere(
      (element) => element.lensDirection == CameraLensDirection.front);

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Timer _timer;
  bool _isRunning = false; // To track whether the code is running or not.

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
    _startTimer();

  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isRunning ? null : _startTimer,
                      child: Text('Start'),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _isRunning ? _stopTimer : null,
                      child: Text('Stop'),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _captureAndSendFrame();
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

void _captureAndSendFrame() async {
  if (!_isRunning) {
    return; // Exit if the code is not running.
  }
  try {
    // Ensure that the camera is initialized.
    await _initializeControllerFuture;

    // Attempt to take a picture and get the file `image`
    // where it was saved.
    final image = await _controller.takePicture();

    Uint8List imagebytes = await image.readAsBytes(); //convert to bytes
    String base64string = base64.encode(imagebytes);
    Map<String, dynamic> fileMap = {
      'image': base64string,
    };
    String jsonEncoded = json.encode(fileMap);
    try {
      print("start to send a frame");
      final startTime = DateTime.now(); // Record the start time

    var response = await Abc.postData(
      "http://192.168.10.64:5000/analyze_frame",
      jsonEncoded,
    );

    final endTime = DateTime.now(); // Record the end time
    final duration = endTime.difference(startTime);

    if (response.statusCode == 200) {
      print("Response received in ${duration.inMilliseconds} milliseconds");
      print(response.data);
      setState(() {
        // ma = "success";
      });
      }
    } catch (e) {
      debugPrint(e.toString());
      // Navigator.pop(context);
    }
  } catch (e) {
    // If an error occurs, log the error to the console.
    print(e);
  }
}
}