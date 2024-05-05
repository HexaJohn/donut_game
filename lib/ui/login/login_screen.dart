import 'package:donut_game/bloc/login/login_bloc.dart';
import 'package:donut_game/bloc/login/login_event.dart';
import 'package:donut_game/bloc/login/login_state.dart';
import 'package:donut_game/ui/internet_play.dart';
import 'package:donut_game/ui/offline_play.dart';
import 'package:donut_game/data/remote/handshake.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:platform_device_id/platform_device_id.dart';

class LoginScreen extends StatefulWidget {
  static const String id = "login_screen";

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

String username = "";
String _serverAddress = '127.0.0.1';
String get serverAddress => _serverAddress;
int port = 27960;

class _LoginScreenState extends State<LoginScreen> {
  late LoginBloc _loginBloc;
  String username = '';
  String serverAddress = '';
  int port = 27960;

  @override
  void initState() {
    super.initState();
    _loginBloc = BlocProvider.of(context);
  }

  @override
  void dispose() {
    // _loginBloc.close();
    super.dispose();
  }

  void _handshake() {
    print('handshaking');
    _loginBloc.add(LoginHandshakeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginBloc, LoginState>(
        builder: (context, state) {
          print('state: $state');
          if (state is LoginInitial) {
            return Center(
              child: SizedBox(
                width: 350,
                height: 500,
                child: Column(
                  children: [
                    const Text('Enter IP and pick a nickname to connect, or play offline against bots:'),
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
                            onPressed: _handshake,
                            child: const Text('Handshake'),
                          ),
                          TextButton(
                              onPressed: () async {
                                var snackbar1 = const SnackBar(content: Text('Logging in...'));
                                ScaffoldMessenger.of(context).showSnackBar(snackbar1);
                                try {
                                  Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/connect');
                                  Response response;
                                  try {
                                    // response = await get(uri);
                                    String? deviceId = await PlatformDeviceId.getDeviceId;
                                    var snackbar2 = const SnackBar(content: Text('Connecting...'));
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackbar2);
                                    String body = '''{"username": "$username", "id": "${deviceId!}"}''';
                                    response = await post(uri, body: body);
                                    var snackbar3 = SnackBar(content: Text('Connecting... (${response.statusCode})'));
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackbar3);
                                    if (response.statusCode == 200) {
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) => OnlineGamePage(
                                              title: '',
                                              username: username,
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      var snackbar = SnackBar(content: Text('Error: ${response.statusCode}'));
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackbar);
                                    }
                                  } catch (e) {
                                    var snackbar = SnackBar(content: Text('Error: $e'));
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackbar);
                                  }
                                } catch (e) {
                                  var snackbar = SnackBar(content: Text('Error: $e'));
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(snackbar);
                                }
                              },
                              child: const Text('Join Game')),
                          TextButton(
                              onPressed: () async {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) => const OfflineGamePage(
                                        title: '',
                                        // username: username,
                                      ),
                                    ),
                                  );
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
            );
          }
          if (state is LoginHandshaking) {
            return const Center(
                child: Card(
                    child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Handshaking with server...'),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            )));
          }

          if (state is LoginSuccess) {
            return Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Server responded with message:'),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(state.serverMessage ?? 'No message from server'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Center(
            child: Text('Error'),
          );
        },
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Navigator.pushNamed(context, GameScreen.id);
          }
        },
      ),
    );
  }
}
