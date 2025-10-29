class AppSizes {
  AppSizes._();

  // Spacing System
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusCircle = 50.0;

  // App Bar
  static const double appBarHeight = 80.0;
  static const double appBarElevation = 0.0;

  // Buttons
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;
  static const double buttonBorderRadius = 16.0;

  // Input Fields
  static const double inputHeight = 56.0;
  static const double inputBorderRadius = 16.0;
  static const double inputBorderWidth = 1.5;

  // Cards
  static const double cardBorderRadius = 20.0;
  static const double cardElevation = 8.0;

  // Icons
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Images & Avatars
  static const double avatarSizeS = 40.0;
  static const double avatarSizeM = 56.0;
  static const double avatarSizeL = 80.0;
  static const double imageAspectRatio = 16/9;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Screen Margins
  static const double screenPadding = 20.0;
  static const double screenPaddingSmall = 16.0;

  // Bottom Navigation
  static const double bottomNavHeight = 80.0;
  static const double bottomNavIconSize = 28.0;

  // Loading Indicators
  static const double loadingIndicatorSize = 32.0;
  static const double loadingIndicatorStroke = 3.0;
}

// Extension for responsive sizing
extension SizeExtensions on double {
  double get responsive => this; // Can be extended with responsive logic
}