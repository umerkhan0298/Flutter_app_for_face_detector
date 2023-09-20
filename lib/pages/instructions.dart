import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'face_detector.dart';

class Introduction extends StatelessWidget {
  final CameraDescription camera; // Accept the camera parameter

  Introduction({required this.camera});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liveliness Detection Challenges"),
      ),
      body: SafeArea(
        child: Center(
            child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/kyc-icon.png"),
                  fit: BoxFit.cover)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0)),
                    tileColor: Theme.of(context).primaryColor,
                    title: const Text(
                      '1) You will be given random challenges to proof your liveliness.' +
                          '\n'
                              '2) Each challenges have 10 seconds to complete.' +
                          '\n'
                              '3) If you fail to complete any of the given challenges then you have to start from scratch.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(
                camera: camera,
              ),
            ),
          );
        },
        tooltip: 'Go to liveliness challenge',
        child: Icon(Icons.navigate_next),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
