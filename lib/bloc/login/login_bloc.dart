import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:donut_game/bloc/login/login_event.dart';
import 'package:donut_game/bloc/login/login_state.dart';
import 'package:donut_game/data/remote/handshake.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginLoadingEvent>(_loginLoading);
    on<LoginLoadedEvent>(_loginLoaded);
    on<LoginHandshakeEvent>(_loginHandshake);
  }

  void _loginLoading(LoginLoadingEvent event, Emitter<LoginState> emit) {
    emit(LoginLoading());
  }

  void _loginLoaded(LoginLoadedEvent event, Emitter<LoginState> emit) {
    emit(LoginLoaded());
  }

  FutureOr<void> _loginHandshake(LoginHandshakeEvent event, Emitter<LoginState> emit) async {
    emit(LoginHandshaking());

    final connection = handshake();

    final listener = connection.listen((event) {
      print('event: $event');
      emit(LoginSuccess(serverMessage: event));
    });

    await listener.asFuture();
  }
}
