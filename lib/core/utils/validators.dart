class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final number = double.tryParse(value);
    if (number == null) return 'Enter a valid number';
    if (number <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  static String? positiveInteger(String? value, {String fieldName = 'Quantity'}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final number = int.tryParse(value);
    if (number == null) return 'Enter a valid integer';
    if (number <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  // Nepal phone: optional country code +977 then 10 digits starting with 98 or 97
  static String? nepalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final clean = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final withoutCode = clean.startsWith('+977')
        ? clean.substring(4)
        : clean.startsWith('977')
            ? clean.substring(3)
            : clean;
    if (!RegExp(r'^(97|98)\d{8}$').hasMatch(withoutCode)) {
      return 'Enter a valid Nepal phone number (e.g. 98XXXXXXXX)';
    }
    return null;
  }

  // Returns 0 (weak), 1 (fair), 2 (strong) for UI strength indicator
  static int passwordStrengthScore(String value) {
    if (value.length < 6) return 0;
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) score++;
    if (score <= 1) return 0;
    if (score <= 2) return 1;
    return 2;
  }
}
