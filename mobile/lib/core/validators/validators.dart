class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9.!#$%&'
    '*+/=?^_`{|}~-]+@'
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static final RegExp _uppercase = RegExp(r'[A-Z]');

  static final RegExp _lowercase = RegExp(r'[a-z]');

  static final RegExp _number = RegExp(r'\d');

  static final RegExp _special = RegExp(
    r'[!@#$%^&*()_\-+=\[\]{};:,.?]',
  );

  static String? validateEmail(
    String value,
  ) {
    final email = value.trim();

    if (email.isEmpty) {
      return 'Ingresa tu correo';
    }

    if (email.length > 254) {
      return 'El correo es demasiado largo';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  static String? validateName(
    String value,
  ) {
    final name = value.trim();

    if (name.isEmpty) {
      return 'Ingresa tu nombre';
    }

    if (name.length > 100) {
      return 'El nombre es demasiado largo';
    }

    return null;
  }

  static String? validateOptionalLastName(
    String? value,
  ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.trim().length > 100) {
      return 'El apellido es demasiado largo';
    }

    return null;
  }

  static List<String> passwordErrors(
    String password,
  ) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add(
        'Debe tener al menos 8 caracteres',
      );
    }

    if (password.length > 64) {
      errors.add(
        'No puede superar 64 caracteres',
      );
    }

    if (!_uppercase.hasMatch(password)) {
      errors.add(
        'Debe incluir una mayúscula',
      );
    }

    if (!_lowercase.hasMatch(password)) {
      errors.add(
        'Debe incluir una minúscula',
      );
    }

    if (!_number.hasMatch(password)) {
      errors.add(
        'Debe incluir un número',
      );
    }

    if (!_special.hasMatch(password)) {
      errors.add(
        'Debe incluir un carácter especial',
      );
    }

    if (password != password.trim()) {
      errors.add(
        'No debe comenzar ni terminar con espacios',
      );
    }

    return errors;
  }

  static String? validatePassword(
    String password,
  ) {
    if (password.isEmpty) {
      return 'Ingresa una contraseña';
    }

    final errors = passwordErrors(
      password,
    );

    if (errors.isEmpty) {
      return null;
    }

    return errors.first;
  }

  /// En login NO obligamos a cumplir la política
  /// de creación de contraseña.
  ///
  /// Solo verificamos que haya un valor y que no
  /// sea absurdamente grande.
  static String? validateLoginPassword(
    String password,
  ) {
    if (password.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (password.length > 64) {
      return 'La contraseña no es válida';
    }

    return null;
  }
}
