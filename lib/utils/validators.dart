class Validators {
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required.';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Price must be a valid number.';
    }
    if (parsed <= 0) {
      return 'Price must be greater than 0.';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required.';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (value.trim().length > 20) {
      return 'Username must be at most 20 characters.';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Image URL is required.';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Please enter a valid image URL (http/https).';
    }
    return null;
  }
}
