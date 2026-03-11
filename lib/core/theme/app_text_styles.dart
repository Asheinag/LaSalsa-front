import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Заголовок экрана (Lora 20px weight 500)
  static TextStyle get screenTitle => GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // Название проекта (Lora 21px weight 500)
  static TextStyle get projectTitle => GoogleFonts.lora(
        fontSize: 21,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // Заголовок в инспекторе (Lora 16px weight 500)
  static TextStyle get inspectorTitle => GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // Заголовок модала (Lora 17px weight 500)
  static TextStyle get modalTitle => GoogleFonts.lora(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // Название задачи в списке (DM Sans 13.5px)
  static TextStyle get taskTitle => GoogleFonts.dmSans(
        fontSize: 13.5,
        color: AppColors.textPrimary,
      );

  // Основной текст (DM Sans 13px)
  static TextStyle get bodyText => GoogleFonts.dmSans(
        fontSize: 13,
        color: AppColors.textPrimary,
      );

  // Вторичный текст (DM Sans 12px)
  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  // Лейбл секции (DM Sans 10.5px uppercase letter-spacing .7px)
  static TextStyle get sectionLabel => GoogleFonts.dmSans(
        fontSize: 10.5,
        color: AppColors.textMuted,
        letterSpacing: 0.7,
      );

  // Лейбл в сайдбаре (DM Sans 10px uppercase letter-spacing .9px)
  static TextStyle get sidebarLabel => GoogleFonts.dmSans(
        fontSize: 10,
        color: AppColors.textMuted,
        letterSpacing: 0.9,
      );

  // Текст тега (DM Sans 11px weight 500)
  static TextStyle get tagLabel => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // Метаданные, даты (DM Sans 11px)
  static TextStyle get metaText => GoogleFonts.dmSans(
        fontSize: 11,
        color: AppColors.textMuted,
      );

  // Кнопки (DM Sans 13px weight 500)
  static TextStyle get buttonText => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );
}
