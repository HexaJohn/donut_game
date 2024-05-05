import 'package:donut_game/routes/route_generator.dart';
import 'package:donut_game/ui/login/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey.shade200,
        cardColor: Colors.grey.shade100,
      ),
      initialRoute: LoginScreen.id,
      onGenerateRoute: RouteGenerator().generateRoute,
    );
  }
}
