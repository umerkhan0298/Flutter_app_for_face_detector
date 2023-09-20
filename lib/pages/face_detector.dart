import 'dart:async';
// import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'fun.dart';
import 'dart:typed_data';
import 'sucessfull.dart';
import 'unsucessfull.dart';
import 'dart:isolate';

// Future<void> main() async {
//   // Ensure that plugin services are initialized so that `availableCameras()`
//   // can be called before `runApp()`
//   WidgetsFlutterBinding.ensureInitialized();

//   // Obtain a list of the available cameras on the device.
//   final cameras = await availableCameras();

//   // Get a specific camera from the list of available cameras.
//   final firstCamera = cameras.firstWhere(
//       (element) => element.lensDirection == CameraLensDirection.front);

//   runApp(
//     MaterialApp(
//       theme: ThemeData.dark(),
//       home: TakePictureScreen(
//         // Pass the appropriate camera to the TakePictureScreen widget.
//         camera: firstCamera,
//       ),
//     ),
//   );
// }
late Timer timerCounter;
const TIMEMAX = 40;

void countdownTimer(SendPort sendPort) {
  int counter = TIMEMAX;
  timerCounter = Timer.periodic(Duration(seconds: 1), (timer) {
    // print(counter);
    counter--;
    sendPort.send(counter);
    if (counter == 0) {
      timerCounter.cancel();
    }
  });
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
  var outputResponse;
  int _counter = TIMEMAX;
  bool _isRunning = false; // To track whether the code is running or not.
  late Isolate _timerIsolate;
  late ReceivePort _timerReceivePort;

  /// ID CHALLENGE NAME
  /// 0  Eye Blinking
  /// 1  Smiling
  /// 2  Head Left Rotation
  /// 3  Head Right Rotation
  /// 4  Head Left Tilting
  /// 5  Head Right Tilting
  static final List<int> randomChallenges =
      List<int>.generate(5, (int index) => index)
        ..shuffle()
        ..add(5);

  /// Random livliness challenge id.
  static int _challengeId = randomChallenges[0];
  int prev_id = _challengeId;

  /// Random livliness challenge index number in the list.
  static int _challengeNo = 0;

  /// Random livliness challenge title.
  String challengeTitle = setChallengeTitle();
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
    // _startTimer();

    // Listen for countdown updates.
  }

  @override
  void dispose() {
    // Terminate the countdown timer isolate.
    _timerIsolate.kill(priority: Isolate.immediate);
    _timerReceivePort.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challengeTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Center(
                child: Text(
              'Time left: $_counter',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.softLight,
                    ),
                    child: CameraPreview(_controller),
                  ),
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

  void startThreadTimer() {
    // print("inside startThreadTimer");
    _timerReceivePort = ReceivePort();
    // Create and spawn the countdown timer isolate.
    Isolate.spawn(countdownTimer, _timerReceivePort.sendPort);

    _timerReceivePort.listen((message) {
      setState(() {
        _counter = message;
        if (_counter == 0) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => Unscucessfull()));
          _isRunning = false;
          _counter = TIMEMAX;
        }
      });
    });
  }

  void _startTimer() {
    startThreadTimer();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _captureAndSendFrame();
    });
    setState(() {
      _isRunning = true;
    });
  }

  void stopThreadTimer() {
    _timerReceivePort.close();
  }

  void _stopTimer() {
    _timer.cancel();
    // stop thread timer
    stopThreadTimer();
    // timerCounter.cancel();
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

      // Set flash mode to off
      await _controller.setFlashMode(FlashMode.off);
      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await _controller.takePicture();

      Uint8List imagebytes = await image.readAsBytes(); //convert to bytes
      String base64string = base64.encode(imagebytes);
      Map<String, dynamic> fileMap = {
        'image': base64string,
        'challenge': _challengeId,
      };
      String jsonEncoded = json.encode(fileMap);
      try {
        print("start to send a frame");
        final startTime = DateTime.now(); // Record the start time

        Response response = await Abc.postData(
          "http://192.168.10.64:5000/analyze_frame",
          // "http://192.168.18.7:5000/analyze_frame",
          jsonEncoded,
        );

        final endTime = DateTime.now(); // Record the end time
        final duration = endTime.difference(startTime);

        if (response.statusCode == 200) {
          // final Map<String, dynamic> data = response.data;
          print("Response received in ${duration.inMilliseconds} milliseconds");
          // if (response.data != null && response.data is Map<String, dynamic>) {
          // Parse the JSON response
          Map<String, dynamic> data = response.data;

          // Access the "message" and "challenge_ID" fields
          String message = data["message"];
          int challengeId = data["challenge_ID"];

          // Now you can use the message and challengeId in your Flutter application
          print("Message: $message");
          print("Challenge ID: $challengeId");
          // } else {
          //   // Handle the case where response.data is null or not in the expected format
          //   print("Invalid or missing response data");}
          if (response.data["message"] == "True" &&
              challengeId == _challengeId) {
            _challengeNo++;
            print(
                "challenge no ${_challengeNo}, challenge id ${_challengeId},length of challenges ${randomChallenges.length}");
            if (_challengeNo < randomChallenges.length) {
              _challengeId = randomChallenges[_challengeNo];
              // prev_id = _challengeId;
              challengeTitle = setChallengeTitle();
              stopThreadTimer();
              // startThreadTimer();
              _startTimer();
            } else {
              _stopTimer();
              print("isrunning ${_isRunning}");
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Scucessfull()));
            }
            // setState(() {

            // });
          }
          outputResponse = response.data;
          // if outputResponse == true{

          // }
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

  static String setChallengeTitle() {
    switch (_challengeId) {
      case 0:
        return "Eye Blinking Challenge";

      case 1:
        return "Smiling Challenge";

      case 2:
        return "Head Left Rotating Challenge";

      case 3:
        return "Head Right Rotating Challenge";

      case 4:
        return "Head Left Tilting Challenge";

      case 5:
        return "Head Right Tilting Challenge";

      default:
        return "";
    }
  }
}
