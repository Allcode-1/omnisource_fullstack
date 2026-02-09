class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Enter email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Некорректный email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) return 'Minimum 8 symbols';
    return null;
  }
}
