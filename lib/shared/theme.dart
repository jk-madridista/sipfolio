import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralised theme for Sipfolio.
///
/// Seed colour: a professional deep teal-blue (`#006B75`) that generates a
/// harmonious Material 3 palette with both light and dark variants.
abstract final class AppTheme {
  /// Brand seed — sits between Material Teal 700 (#00796B) and Cyan 800 (#00838F).
  static const Color brandSeed = Color(0xFF006B75);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark  = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final cs = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:
              BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        prefixIconColor: cs.onSurfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: cs.primary),
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── Navigation bar ────────────────────────────────────────────────────
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleSize: Size(32, 4),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialogs ───────────────────────────────────────────────────────────
      dialogTheme: const DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),

      // ── Snack bar ─────────────────────────────────────────────────────────
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // ── Lists & dividers ──────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Progress indicators ───────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
        linearMinHeight: 6,
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  // Text theme: override weights and letter-spacing only; sizes come from the
  // M3 type scale so they don't need to be specified here.
  static const TextTheme _textTheme = TextTheme(
    displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.3),
    headlineSmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
    titleLarge:   TextStyle(fontWeight: FontWeight.w600),
    titleMedium:  TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0),
    titleSmall:   TextStyle(fontWeight: FontWeight.w500),
    labelLarge:   TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium:  TextStyle(fontWeight: FontWeight.w500),
  );
}
