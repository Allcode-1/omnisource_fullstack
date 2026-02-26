class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Wrong email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Minimum 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Need at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Need at least one number';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Need one special character (!@#\$&*)';
    }
    return null;
  }
}
