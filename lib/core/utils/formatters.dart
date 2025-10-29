class Formatters {
  Formatters._();

  // Text formatting
  static String shorten(String text, [int max = 50]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Number formatting
  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  // Date formatting
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  static String formatChallengeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final challengeDay = DateTime(date.year, date.month, date.day);

    if (challengeDay == today) {
      return 'Today';
    } else if (challengeDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // Social metrics formatting
  static String formatLikes(int likes) {
    if (likes < 1000) return likes.toString();
    if (likes < 10000) return '${(likes / 1000).toStringAsFixed(1)}K';
    if (likes < 1000000) return '${(likes / 1000).toStringAsFixed(0)}K';
    return '${(likes / 1000000).toStringAsFixed(1)}M';
  }

  // Challenge streak formatting
  static String formatStreak(int streak) {
    if (streak == 1) return '1 day';
    return '$streak days';
  }

  // Hashtag formatting
  static String formatHashtag(String tag) {
    if (tag.startsWith('#')) return tag;
    return '#$tag';
  }

  // Username formatting
  static String formatUsername(String username) {
    if (username.startsWith('@')) return username;
    return '@$username';
  }

  // AI prompt formatting
  static String formatPrompt(String prompt) {
    return prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

// Extension for string formatting
extension StringFormatting on String {
  String get shortened => Formatters.shorten(this);
  String get capitalized => Formatters.capitalize(this);
  String get capitalizedWords => Formatters.capitalizeWords(this);
  String get asHashtag => Formatters.formatHashtag(this);
  String get asUsername => Formatters.formatUsername(this);
  String get cleanedPrompt => Formatters.formatPrompt(this);
}