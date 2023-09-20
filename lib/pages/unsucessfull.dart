import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/services.dart';

class Unscucessfull extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Oops! You loss liveliness challenges."),
      ),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/oops.jpg"),
                  fit: BoxFit.cover)),
          child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Card(
                  child: ListTile(
                    tileColor: Theme.of(context).primaryColor,
                    title: const Text(
                      'You are fail to complete our liveliness challenges. Click to start again',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onTap: (){
                      Restart.restartApp();
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (){
                    SystemNavigator.pop();
                }, child: Text('Exit'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
