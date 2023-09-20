import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/instructions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Find the first front-facing camera if available.
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MyApp(
        camera: frontCamera,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kenya KYC Application'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
            child: Container(
                constraints: const BoxConstraints.expand(),
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/kyc-icon.png"),
                        fit: BoxFit.cover)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.0)),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0)),
                        tileColor: Theme.of(context).primaryColor,
                        title: const Text(
                          'Random Liveliness Challenges',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Introduction(
                                camera: camera,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ))),
      ),
    );
  }
}
