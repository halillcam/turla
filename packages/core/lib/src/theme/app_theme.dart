import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/paddings.dart';
import '../constants/radius.dart';
import '../constants/sizes.dart';
import 'app_fonts.dart';
import 'app_text_styles.dart';
import 'panel_text_styles.dart';
import 'round_back_icon.dart';

/// Turla teması (Stitch tasarım sistemi). Mobil ve web aynı temayı kullanır.
abstract final class AppTheme {
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryTint,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.primaryTint,
    onSecondaryContainer: AppColors.primary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onPrimary,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorTint,
    onErrorContainer: AppColors.onErrorTint,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceDim: AppColors.surfaceMuted,
    surfaceBright: AppColors.surface,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainerHighest: AppColors.surfaceMuted,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    shadow: AppColors.scrim,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primaryTint,
    surfaceTint: AppColors.transparent,
  );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayLarge,
    displaySmall: AppTextStyles.display,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineLarge,
    headlineSmall: AppTextStyles.headline,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.labelLarge,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.body,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );

  static const RoundedRectangleBorder _controlShape = RoundedRectangleBorder(
    borderRadius: AppRadius.mdAll,
  );

  static const OutlineInputBorder _inputBorder = OutlineInputBorder(
    borderRadius: AppRadius.mdAll,
    borderSide: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
  );

  /// Web paneli: aynı renkler, daha sıkı ölçek (14 px metin, 40 px düğme/alan, 8 px köşe,
  /// 12 px kart). Stitch "Turla Web" tasarımına göre.
  static ThemeData get panel {
    const controlShape = RoundedRectangleBorder(borderRadius: AppRadius.panelControlAll);
    const inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.panelControlAll,
      borderSide: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );
    const controlSize = Size(AppSizes.minTapTarget, AppSizes.panelControlHeight);
    final base = light;
    final textTheme = base.textTheme.copyWith(
      headlineSmall: PanelTextStyles.pageTitle,
      titleLarge: PanelTextStyles.sectionTitle,
      titleMedium: PanelTextStyles.cardTitle,
      titleSmall: PanelTextStyles.bodyStrong,
      bodyLarge: PanelTextStyles.body,
      bodyMedium: PanelTextStyles.body,
      labelLarge: PanelTextStyles.bodyStrong,
    );
    final primaryStyle = _primaryButtonStyle.copyWith(
      minimumSize: const WidgetStatePropertyAll(controlSize),
      shape: const WidgetStatePropertyAll(controlShape),
      textStyle: const WidgetStatePropertyAll(PanelTextStyles.bodyStrong),
      padding: const WidgetStatePropertyAll(AppPaddings.panelButton),
    );
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      filledButtonTheme: FilledButtonThemeData(style: primaryStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(controlSize),
          shape: const WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(PanelTextStyles.bodyStrong),
          padding: const WidgetStatePropertyAll(AppPaddings.panelButton),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(controlSize),
          shape: const WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(PanelTextStyles.bodyStrong),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: AppPaddings.panelInput,
        hintStyle: PanelTextStyles.body.copyWith(color: AppColors.textMuted),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: AppSizes.focusBorderWidth),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: AppSizes.focusBorderWidth),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: AppSizes.focusBorderWidth),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdPlusAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: PanelTextStyles.sectionTitle,
        contentTextStyle: PanelTextStyles.body,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdPlusAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: PanelTextStyles.body,
        shape: controlShape,
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        dataTextStyle: PanelTextStyles.body,
        dataRowMinHeight: AppSizes.panelRowHeight,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: PanelTextStyles.bodyStrong,
        unselectedLabelStyle: PanelTextStyles.body,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        contentTextStyle: PanelTextStyles.body.copyWith(color: AppColors.surface),
        width: AppSizes.dialogWidth,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      fontFamily: AppFonts.sans,
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        titleTextStyle: AppTextStyles.headline,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: AppSizes.iconLg),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: AppSizes.iconLg),
        shape: Border(
          bottom: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      // Geri düğmesi: açık yüzeyli, ince kenarlıklı daire (kapak görseli üstünde de okunur).
      actionIconTheme: ActionIconThemeData(backButtonIconBuilder: (_) => const RoundBackIcon()),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: AppSizes.iconLg),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSizes.borderWidth,
        space: AppSizes.borderWidth,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _primaryButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(AppSizes.buttonHeight)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.buttonHeight),
          padding: AppPaddings.button,
          shape: _controlShape,
          side: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          padding: AppPaddings.textButton,
          shape: _controlShape,
          textStyle: AppTextStyles.labelLarge,
        ).copyWith(overlayColor: const WidgetStatePropertyAll(AppColors.primaryTint)),
      ),
      iconButtonTheme: IconButtonThemeData(
        // Renk verilmez: dolgulu ikon düğmeleri (gönder) kendi zemin/ön plan rengini korusun;
        // üst çubuk ikonları rengini AppBar temasından alır.
        style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.minTapTarget)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: AppPaddings.input,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTextStyles.labelMedium,
        floatingLabelStyle: AppTextStyles.labelMedium,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        helperStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        errorStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textSecondary,
        border: _inputBorder,
        enabledBorder: _inputBorder,
        disabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: AppSizes.focusBorderWidth),
        ),
        errorBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: AppSizes.focusBorderWidth),
        ),
        focusedErrorBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: AppSizes.focusBorderWidth),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryTint,
        selectionHandleColor: AppColors.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryTint,
        disabledColor: AppColors.surfaceMuted,
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        padding: AppPaddings.chip,
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        height: AppSizes.navigationBarHeight,
        indicatorColor: AppColors.primaryTint,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.navigationIcon,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryTint,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        overlayColor: WidgetStatePropertyAll(AppColors.primaryTint),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textSecondary,
          selectedBackgroundColor: AppColors.primaryTint,
          selectedForegroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
          textStyle: AppTextStyles.labelMedium,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
        titleTextStyle: AppTextStyles.headline,
        contentTextStyle: AppTextStyles.body,
        barrierColor: AppColors.scrim,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.surface),
        actionTextColor: AppColors.primaryTint,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        minVerticalPadding: AppSpacing.md,
        contentPadding: AppPaddings.horizontalLg,
        selectedColor: AppColors.primary,
        selectedTileColor: AppColors.primaryTint,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryTint,
        circularTrackColor: AppColors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        side: const BorderSide(color: AppColors.textSecondary, width: AppSizes.focusBorderWidth),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.surface),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppSizes.menuElevation,
        textStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: AppTextStyles.body,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
        ),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceMuted),
        headingTextStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
        dataTextStyle: AppTextStyles.body,
        dividerThickness: AppSizes.borderWidth,
        headingRowHeight: AppSizes.tableHeadingHeight,
        dataRowMinHeight: AppSizes.tableRowHeight,
        dataRowMaxHeight: AppSizes.tableRowMaxHeight,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.accent,
        textColor: AppColors.onPrimary,
        textStyle: AppTextStyles.labelSmall,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.border),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        shape: Border(),
        collapsedShape: Border(),
      ),
    );
  }

  static ButtonStyle get _primaryButtonStyle =>
      FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceMuted,
        disabledForegroundColor: AppColors.textMuted,
        minimumSize: const Size(AppSizes.minTapTarget, AppSizes.buttonHeight),
        padding: AppPaddings.button,
        elevation: 0,
        shape: _controlShape,
        textStyle: AppTextStyles.labelLarge,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.surfaceMuted;
          if (states.contains(WidgetState.pressed)) return AppColors.primaryPressed;
          return AppColors.primary;
        }),
      );
}
