import 'package:donut_game/server.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:platform_device_id/platform_device_id.dart';

class ServerApp extends StatelessWidget {
  const ServerApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey.shade200,
        cardColor: Colors.grey.shade100,
        // fontFamily: 'FluentIcons'
      ),
      home: const ServerGUI(
          // title: ''
          ),
    );
  }
}

class ServerGUI extends StatefulWidget {
  const ServerGUI({Key? key}) : super(key: key);

  @override
  State<ServerGUI> createState() => _ServerGUIState();
}

class _ServerGUIState extends State<ServerGUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          height: 500,
          child: Column(
            children: [
              Text('SERVER GUI'),
              Card(
                child: TextField(
                  controller: TextEditingController(),
                  decoration: InputDecoration(hintText: 'Run Command:'),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: serverGame.flipFlop,
                  builder: (context, value, child) => ListView.builder(
                    // shrinkWrap: true,
                    itemCount: serverGame.log.length,
                    itemBuilder: (context, index) {
                      return Card(
                          child: Text(
                              '${serverGame.log.keys.toList().reversed.toList()[index]}'));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
