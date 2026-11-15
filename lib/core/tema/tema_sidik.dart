import 'package:flutter/material.dart';

import '../motion/transisi_halaman.dart';
import 'bentuk.dart';
import 'elevasi.dart';
import 'palet_sidik.dart';
import 'spasi.dart';
import 'tipografi.dart';
import 'ukuran.dart';
import 'warna_sidik.dart';

/// Tema SIDIK Pelanggan, arah "Bento Lab": Material 3 datar, navy sebagai warna
/// utama, kuning sebagai aksen, tombol pil, panel dan ubin membulat besar.
///
/// Dua pintu: [TemaSidik.terang] dan [TemaSidik.gelap]. Semua komponen Material
/// (tombol, isian, chip, navigasi, dialog) ditema di sini, sehingga layar cukup
/// memakai widget bawaan atau komponen di `lib/widgets/` tanpa gaya sendiri.
/// Tokennya: `palet_sidik.dart` (warna mentah), `warna_sidik.dart` (status),
/// `spasi.dart`, `bentuk.dart`, `elevasi.dart`, `ukuran.dart`, `tipografi.dart`.
/// Nilai dari `docs/desain-ulang/` (DESIGN.md, tokens.json).
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
    primary: PaletSidik.navy,
    onPrimary: PaletSidik.kartu,
    // Ubin ikon pastel (langit) dengan glif navy; BUKAN penanda pilihan
    // (chip/segmen terpilih memakai primary penuh, lihat di bawah).
    primaryContainer: PaletSidik.langit,
    onPrimaryContainer: PaletSidik.navy,
    secondary: PaletSidik.kuning,
    onSecondary: PaletSidik.navy,
    secondaryContainer: PaletSidik.latar,
    onSecondaryContainer: PaletSidik.navy,
    error: PaletSidik.galat,
    onError: PaletSidik.kartu,
    errorContainer: PaletSidik.koral,
    onErrorContainer: PaletSidik.navy,
    surface: PaletSidik.kartu,
    onSurface: PaletSidik.navy,
    onSurfaceVariant: PaletSidik.teksKedua,
    surfaceContainerLowest: PaletSidik.kartu,
    surfaceContainerLow: PaletSidik.kartu,
    surfaceContainer: PaletSidik.latar,
    surfaceContainerHigh: PaletSidik.latar,
    surfaceContainerHighest: PaletSidik.garis,
    outline: PaletSidik.garisTegas,
    outlineVariant: PaletSidik.garis,
    shadow: PaletSidik.bayangan,
    scrim: PaletSidik.bayangan,
    inverseSurface: PaletSidik.navy,
    onInverseSurface: PaletSidik.kartu,
    inversePrimary: PaletSidik.kuning,
    surfaceTint: Colors.transparent,
  );

  // Tema gelap: titik awal (DESIGN.md §Mode gelap, "belum final").
  static const ColorScheme _skemaGelap = ColorScheme(
    brightness: Brightness.dark,
    primary: PaletSidik.navyTeks,
    onPrimary: PaletSidik.navy,
    primaryContainer: PaletSidik.navyLembut,
    onPrimaryContainer: PaletSidik.teksGelap,
    secondary: PaletSidik.kuning,
    onSecondary: PaletSidik.navy,
    secondaryContainer: PaletSidik.permukaanTinggiGelap,
    onSecondaryContainer: PaletSidik.teksGelap,
    error: PaletSidik.koral,
    onError: PaletSidik.navy,
    errorContainer: PaletSidik.gagalLatarGelap,
    onErrorContainer: PaletSidik.koral,
    surface: PaletSidik.kartuGelap,
    onSurface: PaletSidik.teksGelap,
    onSurfaceVariant: PaletSidik.teksKeduaGelap,
    surfaceContainerLowest: PaletSidik.latarGelap,
    surfaceContainerLow: PaletSidik.permukaanRendahGelap,
    surfaceContainer: PaletSidik.permukaanTinggiGelap,
    surfaceContainerHigh: PaletSidik.permukaanTinggiGelap,
    surfaceContainerHighest: PaletSidik.permukaanTertinggiGelap,
    outline: PaletSidik.garisTegasGelap,
    outlineVariant: PaletSidik.garisHalusGelap,
    shadow: PaletSidik.bayangan,
    scrim: PaletSidik.bayangan,
    inverseSurface: PaletSidik.teksGelap,
    onInverseSurface: PaletSidik.latarGelap,
    inversePrimary: PaletSidik.navy,
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
    final latar = terang ? PaletSidik.latar : PaletSidik.latarGelap;
    final garisHalus = BorderSide(
      color: skema.outlineVariant,
      width: Elevasi.garis,
    );
    // Tombol Bento Lab: pil penuh (utama, sekunder, dan teks).
    const bentukPil = StadiumBorder();

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

      // Kepala layar Bento Lab: setara latar halaman, tanpa bayangan dan tanpa
      // garis bawah (judul 20/26 di kiri; tombol kembali memakai ikon biasa
      // sampai komponen `TombolBulat` masuk di P2).
      appBarTheme: AppBarTheme(
        backgroundColor: latar,
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
      ),

      // Panel datar: permukaan putih, sudut 28, garis halus, tanpa bayangan.
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
          minimumSize: const Size(64, UkuranBaris.tombolUtama),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.xl),
          elevation: Elevasi.datar,
          shape: bentukPil,
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
          shape: bentukPil,
          textStyle: teks.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
          foregroundColor: skema.primary,
          shape: bentukPil,
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
        // Tanpa pil penanda: tujuan aktif = ikon terisi + navy + kata tebal.
        // Dock melayang (butir aktif = pil kuning) menggantikan ini di P4.
        indicatorColor: Colors.transparent,
        elevation: Elevasi.datar,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: UkuranIkon.sedang,
            color: s.contains(WidgetState.selected)
                ? skema.primary
                : skema.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => teks.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected)
                ? skema.primary
                : skema.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: skema.surface,
        indicatorColor: Colors.transparent,
        elevation: Elevasi.datar,
        selectedIconTheme: IconThemeData(
          color: skema.primary,
          size: UkuranIkon.sedang,
        ),
        unselectedIconTheme: IconThemeData(
          color: skema.onSurfaceVariant,
          size: UkuranIkon.sedang,
        ),
        selectedLabelTextStyle: teks.labelMedium?.copyWith(
          color: skema.primary,
          fontWeight: FontWeight.w700,
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
            top: Radius.circular(Bentuk.ubin),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
        backgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Elevasi.lembar,
        shape: RoundedRectangleBorder(borderRadius: Bentuk.sudutPanel),
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
        shape: RoundedRectangleBorder(borderRadius: Bentuk.sudutKapsul),
      ),

      // Saringan Bento Lab: tidak aktif putih + tepi tegas, aktif navy + teks
      // putih (pil). Warna label mengikuti keadaan terpilih.
      chipTheme: ChipThemeData(
        backgroundColor: skema.surface,
        selectedColor: skema.primary,
        checkmarkColor: skema.onPrimary,
        side: BorderSide(color: skema.outline),
        labelStyle: teks.bodySmall?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? skema.onPrimary
                : skema.onSurface,
          ),
          fontWeight: TipografiSidik.beratLabel,
        ),
        secondaryLabelStyle: teks.bodySmall?.copyWith(
          color: skema.onPrimary,
          fontWeight: TipografiSidik.beratLabel,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: Spasi.xs),
      ),
      // Pilihan tampilan (mis. Daftar | Arsip di tab Sertifikat): tinggi
      // sentuh 48 dp, segmen terpilih navy + teks putih (segmen pil Bento Lab).
      // Pemakai tetap WAJIB menyalakan `showSelectedIcon` (centang): warna
      // bukan penanda satu-satunya.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AreaSentuh.minimum),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: skema.outline)),
          textStyle: WidgetStatePropertyAll(teks.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? skema.primary
                : skema.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? skema.onPrimary
                : skema.onSurface,
          ),
        ),
      ),
      // Sakelar Bento Lab: nyala = rel navy + tombol kuning; mati = rel latar
      // + tepi tegas + tombol teks kedua. Tema gelap: rel nyala berwarna
      // terang (primary), jadi tombolnya navy (kuning di atas rel terang
      // tidak terlihat). Ukuran 56 x 36 dari spesifikasi tidak bisa diatur
      // lewat tema Material 3; ditunda ke komponen sakelar.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (terang ? skema.secondary : skema.onPrimary)
              : skema.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? skema.primary : latar,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : skema.outline,
        ),
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
