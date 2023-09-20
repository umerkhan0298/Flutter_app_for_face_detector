import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
class Scucessfull extends StatelessWidget {
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
        title: const Text("Wow! You win."),
      ),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/wow.png"),
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
                      'You have successfully complete our liveliness challenges. Click to start again',
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
