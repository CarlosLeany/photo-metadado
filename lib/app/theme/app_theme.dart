import 'package:flutter/material.dart';
import 'package:flutter_template/app/theme/app_colors.dart';

class AppTheme {
  // Estilo comum para evitar repetição (Bordas)
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  // --- TEMA CLARO ---
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: AppColors.surfaceLight,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        
        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFillLight,
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary),
        ),

        // Botões
        elevatedButtonTheme: _elevatedButton(AppColors.primary, Colors.white),
        outlinedButtonTheme: _outlinedButton(AppColors.primary),
        
        // Dropdown
        dropdownMenuTheme: _dropdownTheme(AppColors.inputFillLight),
      );

  // --- TEMA ESCURO ---
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          surface: AppColors.surfaceDark,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFillDark,
          border: _border(AppColors.borderDark),
          enabledBorder: _border(AppColors.borderDark),
          focusedBorder: _border(AppColors.primary),
        ),

        // Botões (mantêm a cor primária, mas você pode ajustar se quiser)
        elevatedButtonTheme: _elevatedButton(AppColors.primary, Colors.white),
        outlinedButtonTheme: _outlinedButton(AppColors.primary),

        // Dropdown
        dropdownMenuTheme: _dropdownTheme(AppColors.inputFillDark),
      );

  // --- AUXILIARES DE ESTILO ---
  static ElevatedButtonThemeData _elevatedButton(Color bg, Color fg) => 
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

  static OutlinedButtonThemeData _outlinedButton(Color color) => 
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

  static DropdownMenuThemeData _dropdownTheme(Color fill) => 
    DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}