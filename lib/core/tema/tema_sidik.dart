import 'package:flutter/material.dart';

import '../motion/transisi_halaman.dart';
import 'bentuk.dart';
import 'elevasi.dart';
import 'palet_sidik.dart';
import 'spasi.dart';
import 'tipografi.dart';
import 'ukuran.dart';
import 'warna_sidik.dart';

/// Tema SIDIK Pelanggan: Material 3 datar, elevasi rendah, ruang putih lega.
///
/// Dua pintu: [TemaSidik.terang] dan [TemaSidik.gelap]. Semua komponen Material
/// (tombol, isian, chip, navigasi, dialog) ditema di sini, sehingga layar cukup
/// memakai widget bawaan atau komponen di `lib/widgets/` tanpa gaya sendiri.
/// Tokennya: `palet_sidik.dart` (warna mentah), `warna_sidik.dart` (status),
/// `spasi.dart`, `bentuk.dart`, `elevasi.dart`, `ukuran.dart`, `tipografi.dart`.
abstract final class TemaSidik {
  static final ThemeData terang = _bangun(
    skema: _skemaTerang,
    status: WarnaSidik.terang,
  );

  static final ThemeData gelap = _bangun(
    skema: _skemaGelap,
    status: WarnaSidik.gelap,
  );

  static const ColorScheme _skemaTerang = ColorScheme(
    brightness: Brightness.light,
    primary: PaletSidik.kobalt,
    onPrimary: PaletSidik.permukaanTerang,
    primaryContainer: PaletSidik.kobaltTipis,
    onPrimaryContainer: PaletSidik.kobaltTua,
    secondary: PaletSidik.teksKeduaTerang,
    onSecondary: PaletSidik.permukaanTerang,
    secondaryContainer: PaletSidik.permukaanTinggiTerang,
    onSecondaryContainer: PaletSidik.teksTerang,
    error: PaletSidik.gagalTerang,
    onError: PaletSidik.permukaanTerang,
    errorContainer: PaletSidik.gagalLatarTerang,
    onErrorContainer: PaletSidik.gagalTerang,
    surface: PaletSidik.permukaanTerang,
    onSurface: PaletSidik.teksTerang,
    onSurfaceVariant: PaletSidik.teksKeduaTerang,
    surfaceContainerLowest: PaletSidik.permukaanTerang,
    surfaceContainerLow: PaletSidik.permukaanRendahTerang,
    surfaceContainer: PaletSidik.latarTerang,
    surfaceContainerHigh: PaletSidik.permukaanTinggiTerang,
    surfaceContainerHighest: PaletSidik.permukaanTertinggiTerang,
    outline: PaletSidik.garisTerang,
    outlineVariant: PaletSidik.garisHalusTerang,
    shadow: PaletSidik.bayangan,
    scrim: PaletSidik.bayangan,
    inverseSurface: PaletSidik.teksTerang,
    onInverseSurface: PaletSidik.latarTerang,
    inversePrimary: PaletSidik.kobaltTerang,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _skemaGelap = ColorScheme(
    brightness: Brightness.dark,
    primary: PaletSidik.kobaltTerang,
    onPrimary: PaletSidik.kobaltTerangTua,
    primaryContainer: PaletSidik.kobaltGelapTipis,
    onPrimaryContainer: PaletSidik.kobaltGelapTeks,
    secondary: PaletSidik.teksKeduaGelap,
    onSecondary: PaletSidik.latarGelap,
    secondaryContainer: PaletSidik.permukaanTinggiGelap,
    onSecondaryContainer: PaletSidik.teksGelap,
    error: PaletSidik.gagalGelap,
    onError: PaletSidik.latarGelap,
    errorContainer: PaletSidik.gagalLatarGelap,
    onErrorContainer: PaletSidik.gagalGelap,
    surface: PaletSidik.permukaanGelap,
    onSurface: PaletSidik.teksGelap,
    onSurfaceVariant: PaletSidik.teksKeduaGelap,
    surfaceContainerLowest: PaletSidik.latarGelap,
    surfaceContainerLow: PaletSidik.permukaanRendahGelap,
    surfaceContainer: PaletSidik.permukaanTinggiGelap,
    surfaceContainerHigh: PaletSidik.permukaanTinggiGelap,
    surfaceContainerHighest: PaletSidik.permukaanTertinggiGelap,
    outline: PaletSidik.garisGelap,
    outlineVariant: PaletSidik.garisHalusGelap,
    shadow: PaletSidik.bayangan,
    scrim: PaletSidik.bayangan,
    inverseSurface: PaletSidik.teksGelap,
    onInverseSurface: PaletSidik.latarGelap,
    inversePrimary: PaletSidik.kobalt,
    surfaceTint: Colors.transparent,
  );

  static ThemeData _bangun({
    required ColorScheme skema,
    required WarnaSidik status,
  }) {
    final teks = TipografiSidik.skala(
      teks: skema.onSurface,
      teksKedua: skema.onSurfaceVariant,
    );
    final terang = skema.brightness == Brightness.light;
    final latar = terang ? PaletSidik.latarTerang : PaletSidik.latarGelap;
    final garisHalus = BorderSide(
      color: skema.outlineVariant,
      width: Elevasi.garis,
    );
    final bentukKontrol = RoundedRectangleBorder(
      borderRadius: Bentuk.sudutKontrol,
    );

    InputBorder isian(Color warna, [double tebal = 1]) => OutlineInputBorder(
      borderRadius: Bentuk.sudutKontrol,
      borderSide: BorderSide(color: warna, width: tebal),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: skema.brightness,
      colorScheme: skema,
      fontFamily: TipografiSidik.keluarga,
      textTheme: teks,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: latar,
      canvasColor: latar,
      dividerColor: skema.outlineVariant,
      extensions: <ThemeExtension<dynamic>>[status],

      // Transisi halaman halus bawaan proyek; iOS/macOS tetap bawaan platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: TransisiHalus(),
          TargetPlatform.fuchsia: TransisiHalus(),
          TargetPlatform.linux: TransisiHalus(),
          TargetPlatform.windows: TransisiHalus(),
        },
      ),

      // App bar putih, tanpa bayangan, dibatasi garis halus.
      appBarTheme: AppBarTheme(
        backgroundColor: skema.surface,
        foregroundColor: skema.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevasi.datar,
        scrolledUnderElevation: Elevasi.datar,
        centerTitle: false,
        titleTextStyle: teks.titleLarge,
        iconTheme: IconThemeData(
          color: skema.onSurface,
          size: UkuranIkon.sedang,
        ),
        shape: Border(bottom: garisHalus),
      ),

      // Kartu datar: permukaan putih + garis halus, tanpa bayangan.
      cardTheme: CardThemeData(
        elevation: Elevasi.datar,
        color: skema.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Bentuk.sudutKartu,
          side: garisHalus,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.xl),
          elevation: Elevasi.datar,
          shape: bentukKontrol,
          textStyle: teks.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.xl),
          foregroundColor: skema.primary,
          backgroundColor: skema.surface,
          side: BorderSide(color: skema.outline),
          shape: bentukKontrol,
          textStyle: teks.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
          foregroundColor: skema.primary,
          shape: bentukKontrol,
          textStyle: teks.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AreaSentuh.minimum),
          foregroundColor: skema.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: skema.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spasi.lg,
          vertical: Spasi.md,
        ),
        hintStyle: teks.bodyMedium?.copyWith(color: skema.onSurfaceVariant),
        labelStyle: teks.bodyMedium?.copyWith(color: skema.onSurfaceVariant),
        helperStyle: teks.bodySmall,
        errorStyle: teks.bodySmall?.copyWith(color: skema.error),
        prefixIconColor: skema.onSurfaceVariant,
        suffixIconColor: skema.onSurfaceVariant,
        border: isian(skema.outline),
        enabledBorder: isian(skema.outline),
        focusedBorder: isian(skema.primary, 2),
        errorBorder: isian(skema.error),
        focusedErrorBorder: isian(skema.error, 2),
        disabledBorder: isian(skema.outlineVariant),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: skema.primaryContainer,
        elevation: Elevasi.datar,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: UkuranIkon.sedang,
            color: s.contains(WidgetState.selected)
                ? skema.onPrimaryContainer
                : skema.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => teks.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected)
                ? skema.onSurface
                : skema.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: skema.surface,
        indicatorColor: skema.primaryContainer,
        elevation: Elevasi.datar,
        selectedIconTheme: IconThemeData(
          color: skema.onPrimaryContainer,
          size: UkuranIkon.sedang,
        ),
        unselectedIconTheme: IconThemeData(
          color: skema.onSurfaceVariant,
          size: UkuranIkon.sedang,
        ),
        selectedLabelTextStyle: teks.labelMedium?.copyWith(
          color: skema.onSurface,
        ),
        unselectedLabelTextStyle: teks.labelMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: skema.surface,
        modalBackgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevasi.lembar,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Bentuk.lembar),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
        backgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevasi.lembar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Bentuk.lembar),
        ),
        titleTextStyle: teks.titleLarge,
        contentTextStyle: teks.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: skema.inverseSurface,
        contentTextStyle: teks.bodyMedium?.copyWith(
          color: skema.onInverseSurface,
        ),
        actionTextColor: skema.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: Elevasi.rendah,
        shape: bentukKontrol,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: skema.surface,
        selectedColor: skema.primaryContainer,
        checkmarkColor: skema.onPrimaryContainer,
        side: BorderSide(color: skema.outline),
        labelStyle: teks.bodySmall?.copyWith(
          color: skema.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: teks.bodySmall?.copyWith(
          color: skema.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: Spasi.xs),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: skema.onSurfaceVariant,
        textColor: skema.onSurface,
        minVerticalPadding: Spasi.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
        titleTextStyle: teks.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: teks.bodySmall,
      ),
      dividerTheme: DividerThemeData(
        color: skema.outlineVariant,
        thickness: Elevasi.garis,
        space: Elevasi.garis,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: skema.primary,
        linearTrackColor: skema.surfaceContainerHigh,
        circularTrackColor: skema.surfaceContainerHigh,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: skema.inverseSurface,
          borderRadius: Bentuk.sudutKecil,
        ),
        textStyle: teks.bodySmall?.copyWith(color: skema.onInverseSurface),
      ),
    );
  }
}
