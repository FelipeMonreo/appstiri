import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Semantic colors keep every screen in sync with the phone's system theme.
abstract final class AppTheme {
  static const blue = Color(0xFF1557CD);
  static const charcoal = Color(0xFF191B20);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: dark ? const Color(0xFF858A95) : blue,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFF4F5F7) : blue,
          onPrimary: dark ? charcoal : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF343841)
              : const Color(0xFFE5EDFF),
          onPrimaryContainer: dark ? Colors.white : const Color(0xFF113C8C),
          secondary: dark ? const Color(0xFFD6D9DF) : const Color(0xFF315A98),
          onSecondary: dark ? charcoal : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF343841)
              : const Color(0xFFE5EDFF),
          onSecondaryContainer: dark ? Colors.white : const Color(0xFF113C8C),
          surface: dark ? const Color(0xFF24272D) : Colors.white,
          onSurface: dark ? const Color(0xFFF4F5F7) : const Color(0xFF17233A),
          onSurfaceVariant: dark
              ? const Color(0xFFB9BEC8)
              : const Color(0xFF526078),
          surfaceContainerLowest: dark ? charcoal : const Color(0xFFF3F6FC),
          surfaceContainerLow: dark
              ? const Color(0xFF202329)
              : const Color(0xFFEDF2FC),
          surfaceContainer: dark
              ? const Color(0xFF2C3037)
              : const Color(0xFFE9EFFA),
          surfaceContainerHigh: dark
              ? const Color(0xFF343841)
              : const Color(0xFFE2EAFA),
          surfaceContainerHighest: dark
              ? const Color(0xFF3B404A)
              : const Color(0xFFDAE5F8),
          outline: dark ? const Color(0xFF89919F) : const Color(0xFF7686A0),
          outlineVariant: dark
              ? const Color(0xFF414650)
              : const Color(0xFFD3DDEF),
          error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFAA242C),
          errorContainer: dark
              ? const Color(0xFF48272C)
              : const Color(0xFFFFEDEF),
          onErrorContainer: dark
              ? const Color(0xFFFFDAD6)
              : const Color(0xFF751A23),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final text = base.textTheme.copyWith(
      displaySmall: TextStyle(
        fontFamily: 'Bitter',
        fontSize: 44,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.3,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Bitter',
        fontSize: 36,
        height: 1.18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Bitter',
        fontSize: 30,
        height: 1.22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Bitter',
        fontSize: 25,
        height: 1.28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 21,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 17,
        height: 1.65,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        height: 1.55,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        systemOverlayStyle:
            (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: scheme.surface,
                  systemNavigationBarIconBrightness: dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: shape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: shape,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 25,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelLarge!.copyWith(fontSize: 13),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: shape,
        showCloseIcon: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.all(18),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      // The SDK preserves Cupertino swipe-back and Android predictive back.
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
