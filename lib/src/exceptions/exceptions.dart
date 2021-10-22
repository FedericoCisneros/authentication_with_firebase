import 'package:authentication_with_firebase/src/exceptions/exception_codes.dart';

class AuthenticationException implements Exception {
  String message;
  ExceptionCodes code;
  AuthenticationException({ExceptionCodes code}) {
    this.code = code;
    switch (code) {
      case ExceptionCodes.ACTION_CODE_SETTINGS:
        message =
            "Falta configurar los action code settings para generar el dynamic link";
        break;
      case ExceptionCodes.INVALID_EMAIL:
        message = "Email ingresado no valid";
        break;
      case ExceptionCodes.INVALID_PASSWORD:
        message = "Contraseña invalida";
        break;
      case ExceptionCodes.WRONG_PASSWORD:
        message = "Contraseña incorrecta";
        break;
      case ExceptionCodes.USER_NOT_FOUND:
        message = "Usuario no encontrado";
        break;
      case ExceptionCodes.EXPIRED_ACTION_CODE:
        message = "El codigo de action expiro";
        break;
      case ExceptionCodes.USER_DISABLED:
        message = "Usuario deshabilitado";
        break;
    }
  }
}
