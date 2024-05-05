abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginHandshaking extends LoginState {}

class LoginLoading extends LoginState {}

class LoginLoaded extends LoginState {}

class LoginError extends LoginState {}

class LoginSuccess extends LoginState {
  String serverMessage;
  LoginSuccess({required this.serverMessage});
}

class LoginFailure extends LoginState {}

class LoginLogout extends LoginState {}

class LoginLogoutSuccess extends LoginState {}

class LoginLogoutFailure extends LoginState {}

class LoginLogoutLoading extends LoginState {}
