import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'request.dart';
import 'dart:typed_data';
import 'sucessfull.dart';
import 'unsucessfull.dart';
import 'dart:isolate';

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

class RectanglePainter extends CustomPainter {
  final int challengeId;
  RectanglePainter(this.challengeId);
  @override
  void paint(Canvas canvas, Size size) {
    if (challengeId == 6) {
      // print("inside painter");
      final Paint paint = Paint()
        ..color = Colors.red // Rectangle color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0; // Rectangle border width

      final Rect rect_nose = Rect.fromLTRB(
        140, // X-coordinate of the top-left corner
        250, // Y-coordinate of the top-left corner
        220, // X-coordinate of the bottom-right corner
        320, // Y-coordinate of the bottom-right corner
      );
      final Rect rect_face = Rect.fromLTRB(
        70, // X-coordinate of the top-left corner
        90, // Y-coordinate of the top-left corner
        290, // X-coordinate of the bottom-right corner
        420, // Y-coordinate of the bottom-right corner
      );
    canvas.drawRect(rect_nose, paint); // Draw the rectangle of nose on the canvas
    canvas.drawRect(rect_face, paint); // Draw the rectangle of face on the canvas
  }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
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
  /// 6  Nose Placement with Frontal Upright Face
  static final List<int> randomChallenges =
      List<int>.generate(6, (int index) => index)
        ..shuffle()
        ..add(6);

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
                  
                  child: Stack(
                    children: <Widget>[
                      // Positioned(
                        // left: 0,
                        // top: 0,
                        // width: 50,
                        // height: 50,
                      // )
                      // ColorFiltered(
                      //   colorFilter: const ColorFilter.mode(
                      //     Colors.white,
                      //     BlendMode.softLight,
                      //   ),
                      // child:
                      Transform.scale(
                        scaleX: 1,
                        scaleY: 1.3,
                        alignment: Alignment.topCenter,


                        // child: AspectRatio(
                        //   aspectRatio: _controller.value.aspectRatio,
                        child: CameraPreview(_controller),
                        // ),
                        //  ),
                      ),
                      // ),
                      CustomPaint(
                        // size: Size(500, 500),
                        painter: RectanglePainter(_challengeId),
                      ),
                    ],
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
          "http://192.168.10.73:5000/analyze_frame",
          // "http://192.168.10.64:5000/analyze_frame",
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

      case 6:
        return "Frontal Upright Face with \n Nose in Box Challenge";

      default:
        return "";
    }
  }
}
