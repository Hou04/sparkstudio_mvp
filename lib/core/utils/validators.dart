class Validators {
  Validators._();

  // Email validation
  static bool isEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
      caseSensitive: false,
    );
    return emailRegex.hasMatch(value.trim());
  }

  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password validation
  static bool isStrongPassword(String? value) {
    if (value == null || value.isEmpty) return false;
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(value);
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!isStrongPassword(value)) {
      return 'Password must include uppercase, lowercase, number, and special character';
    }
    return null;
  }

  static String? confirmPasswordValidator(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Username validation
  static bool isValidUsername(String? value) {
    if (value == null || value.isEmpty) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(value);
  }

  static String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!isValidUsername(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  // Display name validation
  static bool isValidDisplayName(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 2 && value.length <= 30;
  }

  static String? displayNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Display name is required';
    }
    if (value.length < 2) {
      return 'Display name must be at least 2 characters long';
    }
    if (value.length > 30) {
      return 'Display name must be less than 30 characters';
    }
    return null;
  }

  // Challenge title validation
  static bool isValidChallengeTitle(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 5 && value.length <= 100;
  }

  static String? challengeTitleValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Challenge title is required';
    }
    if (value.length < 5) {
      return 'Title must be at least 5 characters long';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  // Challenge description validation
  static bool isValidChallengeDescription(String? value) {
    if (value == null) return true; // Optional field
    return value.length <= 500;
  }

  static String? challengeDescriptionValidator(String? value) {
    if (value != null && value.length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  // Creative content validation
  static bool isValidCreativeContent(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 10 && value.length <= 2000;
  }

  static String? creativeContentValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Content is required';
    }
    if (value.length < 10) {
      return 'Content must be at least 10 characters long';
    }
    if (value.length > 2000) {
      return 'Content must be less than 2000 characters';
    }
    return null;
  }

  // Hashtag validation
  static bool isValidHashtag(String? value) {
    if (value == null || value.isEmpty) return false;
    final hashtagRegex = RegExp(r'^#[a-zA-Z0-9_]{1,29}$');
    return hashtagRegex.hasMatch(value);
  }

  static String? hashtagValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hashtag is required';
    }
    if (!isValidHashtag(value)) {
      return 'Hashtag must start with # and contain only letters, numbers, and underscores';
    }
    return null;
  }

  // AI prompt validation
  static bool isValidAIPrompt(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 5 && value.length <= 1000;
  }

  static String? aiPromptValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Prompt is required';
    }
    if (value.length < 5) {
      return 'Prompt must be at least 5 characters long';
    }
    if (value.length > 1000) {
      return 'Prompt must be less than 1000 characters';
    }
    return null;
  }

  // File size validation (in bytes)
  static bool isValidFileSize(int fileSize, [int maxSize = 10 * 1024 * 1024]) {
    return fileSize <= maxSize;
  }

  static String? fileSizeValidator(int fileSize, [int maxSize = 10 * 1024 * 1024]) {
    if (!isValidFileSize(fileSize, maxSize)) {
      return 'File size must be less than ${(maxSize / (1024 * 1024)).toStringAsFixed(0)}MB';
    }
    return null;
  }

  // Combined validation for multiple fields
  static Map<String, String?> validateSignup({
    required String? email,
    required String? password,
    required String? confirmPassword,
    required String? username,
    required String? displayName,
  }) {
    return {
      'email': emailValidator(email),
      'password': passwordValidator(password),
      'confirmPassword': confirmPasswordValidator(confirmPassword, password),
      'username': usernameValidator(username),
      'displayName': displayNameValidator(displayName),
    };
  }

  // Check if all validations pass
  static bool isFormValid(Map<String, String?> validations) {
    return validations.values.every((error) => error == null);
  }
}

// Extension for easy validation
extension ValidationExtensions on String {
  bool get isEmail => Validators.isEmail(this);
  bool get isStrongPassword => Validators.isStrongPassword(this);
  bool get isValidUsername => Validators.isValidUsername(this);
  bool get isValidDisplayName => Validators.isValidDisplayName(this);
  bool get isValidHashtag => Validators.isValidHashtag(this);
  bool get isValidAIPrompt => Validators.isValidAIPrompt(this);
}