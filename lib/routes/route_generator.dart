import 'package:donut_game/bloc/login/login_bloc.dart';
import 'package:donut_game/ui/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteGenerator {
  Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case LoginScreen.id:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<LoginBloc>.value(
            value: LoginBloc(),
            child: const LoginScreen(),
          ),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Error while loading new page'),
        ),
      );
    });
  }
}
