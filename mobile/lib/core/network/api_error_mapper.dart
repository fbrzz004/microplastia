import 'api_exception.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static ApiException fromStatusCode(
    int statusCode, {
    String? serverMessage,
  }) {
    switch (statusCode) {
      case 400:
        return ApiException(
          statusCode: 400,
          message: serverMessage ?? 'Revisa los datos enviados.',
        );

      case 401:
        return const ApiException(
          statusCode: 401,
          sessionExpired: true,
          message: 'Tu sesión expiró. '
              'Inicia sesión nuevamente.',
        );

      case 403:
        return const ApiException(
          statusCode: 403,
          message: 'No tienes permisos para '
              'realizar esta operación.',
        );

      case 404:
        return ApiException(
          statusCode: 404,
          message: serverMessage ?? 'El recurso solicitado no existe.',
        );

      case 413:
        return const ApiException(
          statusCode: 413,
          message: 'La imagen supera el tamaño '
              'máximo permitido.',
        );

      case 422:
        return const ApiException(
          statusCode: 422,
          message: 'Algunos datos enviados '
              'no son válidos.',
        );

      case 429:
        return const ApiException(
          statusCode: 429,
          message: 'Se realizaron demasiados '
              'intentos. Inténtalo más tarde.',
        );

      case 500:
        return const ApiException(
          statusCode: 500,
          message: 'Ocurrió un problema en el servidor.',
        );

      case 503:
        return const ApiException(
          statusCode: 503,
          message: 'El servicio no está disponible '
              'temporalmente.',
        );

      default:
        return const ApiException(
          message: 'No se pudo completar '
              'la operación.',
        );
    }
  }
}
