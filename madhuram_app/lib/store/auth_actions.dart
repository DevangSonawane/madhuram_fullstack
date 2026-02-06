class LoginStart {}

class LoginSuccess {
  final Map<String, dynamic> user;
  LoginSuccess(this.user);
}

class LoginFailure {
  final String error;
  LoginFailure(this.error);
}

class Logout {}
