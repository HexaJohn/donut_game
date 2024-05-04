import 'package:donut_game/ws_server.dart';
import 'package:flutter/material.dart';

class ServerHome extends StatelessWidget {
  const ServerHome({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey.shade200,
        cardColor: Colors.grey.shade100,
      ),
      home: const ServerGUI(),
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
        child: SizedBox(
          width: 350,
          height: 500,
          child: Column(
            children: [
              const Text('SERVER GUI'),
              Card(
                child: TextField(
                  controller: TextEditingController(),
                  decoration: const InputDecoration(hintText: 'Run Command:'),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: serverGame.flipFlop,
                  builder: (context, value, child) => ListView.builder(
                    itemCount: serverGame.log.length,
                    itemBuilder: (context, index) {
                      return Card(child: Text(serverGame.log.keys.toList().reversed.toList()[index]));
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
