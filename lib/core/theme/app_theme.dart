import 'dart:ui';

import 'package:flutter/material.dart';

/// c3 – Creator Club design tokens and themes.
/// - Primary (Deep Indigo): #3533CD
/// - Dark Gray: #363433
/// - White: #FFFFFF
///
/// Light → background: white, text: dark gray, primary: indigo
/// Dark  → background: dark gray, text: white, primary: indigo
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3533CD);
  static const Color darkGray = Color(0xFF141414);
  static const Color white = Color(0xFFFFFFFF);
}

/// Design tokens exposed to widgets via ThemeExtension.
/// Access with: `context.theme.extension<AppTokens>()!`
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final EdgeInsets buttonPadding;

  const AppTokens({
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.buttonPadding,
  });

  static const AppTokens defaults = AppTokens(
    radiusSmall: 8,
    radiusMedium: 12,
    radiusLarge: 16,
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  AppTokens copyWith({
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    EdgeInsets? buttonPadding,
  }) {
    return AppTokens(
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      buttonPadding: buttonPadding ?? this.buttonPadding,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
      buttonPadding: EdgeInsets.lerp(buttonPadding, other.buttonPadding, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Garet';

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  /// Single source of truth: build ThemeData from a brightness + tokens.
  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      // Align neutral surfaces to your spec:
      surface: isDark ? AppColors.darkGray : AppColors.white,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
    ).copyWith(onSurface: isDark ? AppColors.white : AppColors.darkGray);

    final tokens = AppTokens.defaults;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.defaults],
    );

    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme,
      // AppBar
      appBarTheme: _appBarTheme(scheme, textTheme),
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(scheme, textTheme, tokens),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(scheme, textTheme, tokens),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(scheme, textTheme, tokens, isDark),
      ),
      // Inputs
      inputDecorationTheme: _inputDecorationTheme(
        scheme,
        textTheme,
        tokens,
        isDark,
      ),
      // Dividers
      dividerTheme: DividerThemeData(
        color: (isDark ? AppColors.white : AppColors.darkGray).withValues(
          alpha: 0.12,
        ),
        thickness: 1,
        space: 1,
      ),
      // Cards
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
      ),
      // Chips
      chipTheme: base.chipTheme.copyWith(
        color: WidgetStatePropertyAll(isDark ? scheme.surface : scheme.surface),
        side: BorderSide(
          color: (isDark ? AppColors.white : AppColors.darkGray).withValues(
            alpha: 0.12,
          ),
        ),
        labelStyle: textTheme.labelLarge,
        shape: StadiumBorder(side: BorderSide.none),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  // ----- Sub-builders (hierarchy) -------------------------------------------

  static AppBarTheme _appBarTheme(ColorScheme scheme, TextTheme textTheme) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }

  static ButtonStyle _baseButtonShape(AppTokens tokens) {
    return ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
      ),
      padding: WidgetStatePropertyAll(tokens.buttonPadding),
      minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
      tapTargetSize: MaterialTapTargetSize.padded,
      enableFeedback: true,
    );
  }

  static ButtonStyle _filledButtonStyle(
    ColorScheme scheme,
    TextTheme text,
    AppTokens tokens,
  ) {
    return _baseButtonShape(tokens).merge(
      ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.primary),
        foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
        textStyle: WidgetStatePropertyAll(
          text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme scheme,
    TextTheme text,
    AppTokens tokens,
    bool isDark,
  ) {
    final borderColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.32)
        : scheme.primary;
    final fg = isDark ? scheme.onSurface : scheme.primary;

    return _baseButtonShape(tokens).merge(
      ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(fg),
        side: WidgetStatePropertyAll(
          BorderSide(color: borderColor, width: 1.2),
        ),
        textStyle: WidgetStatePropertyAll(
          text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    ColorScheme scheme,
    TextTheme text,
    AppTokens tokens,
    bool isDark,
  ) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          borderSide: BorderSide(color: color, width: width),
        );

    final fill = isDark
        ? AppColors.white.withValues(alpha: 0.06)
        : scheme.surface.withValues(alpha: 0.90);

    final idleBorderColor = isDark
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.darkGray.withValues(alpha: 0.15);

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(idleBorderColor),
      enabledBorder: border(idleBorderColor),
      focusedBorder: border(scheme.primary, 1.5),
      hintStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: isDark ? 0.65 : 0.5),
      ),
      labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
    );
  }
}

// Handy extension for quick access to tokens
// (removed unused _ThemeX extension)
