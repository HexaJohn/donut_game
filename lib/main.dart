import 'dart:io';

import 'package:donut_game/screens/internet_play.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:platform_device_id/platform_device_id.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      home: const LoginPage(
          // title: ''
          ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

String username = "John's MacBook Pro";
String _serverAddress = '192.168.1.113';
String get serverAddress => _serverAddress;
int port = 443;

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          height: 500,
          child: Column(
            children: [
              const Text(
                  'Enter IP and pick a nickname to connect, or play offline:'),
              TextField(
                  controller: TextEditingController(text: _serverAddress),
                  decoration: const InputDecoration(hintText: 'IP Address'),
                  onChanged: (s) {
                    _serverAddress = s;
                  }),
              TextField(
                  controller: TextEditingController(text: username),
                  decoration: const InputDecoration(hintText: 'Nickname'),
                  onChanged: (s) {
                    username = s;
                  }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () async {
                          try {
                            Uri uri = Uri(
                                scheme: 'http',
                                host: serverAddress,
                                port: port,
                                path: '/connect');
                            Response response;
                            try {
                              // response = await get(uri);
                              String? deviceId =
                                  await PlatformDeviceId.getDeviceId;

                              String body = '''
{"username": "$username", "id": "${deviceId!}"}''';
                              response = await post(uri, body: body);
                              if (response.statusCode == 200) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        OnlineGamePage(
                                      title: '',
                                      username: username,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              var snackbar =
                                  SnackBar(content: Text('Error: $e'));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackbar);
                              print('Error: $e');
                            }
                          } catch (e) {
                            var snackbar = SnackBar(content: Text('Error: $e'));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackbar);
                            print('FAILED: $e');
                          }
                        },
                        child: const Text('Join Game')),
                    TextButton(
                        onPressed: () async {
                          try {
                            // var res = await http
                            // .get(Uri.tryParse('173.24.236.183/connect')!);
                            // res.statusCode;
                            // var snackbar = SnackBar(content: Text('bad request'));
                            // ScaffoldMessenger.of(context).showSnackBar(snackbar);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        OnlineGamePage(
                                          title: '',
                                          username: username,
                                        )));
                          } catch (e) {
                            // TODO
                          }
                        },
                        child: const Text('Play Offline'))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
