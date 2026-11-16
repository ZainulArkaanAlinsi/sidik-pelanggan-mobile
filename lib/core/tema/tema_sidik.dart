import 'package:flutter/material.dart';

import '../motion/transisi_halaman.dart';
import 'bentuk.dart';
import 'elevasi.dart';
import 'palet_sidik.dart';
import 'spasi.dart';
import 'tipografi.dart';
import 'ukuran.dart';
import 'warna_sidik.dart';

/// Tema SIDIK Pelanggan, arah tenang-formal-ringkas (REVISI 16 Nov 2026):
/// Material 3 datar, biru sebagai warna aksi, navy untuk teks, biru muda untuk
/// pilihan aktif, tombol dan isian bersudut 10-12, kartu 16. Warna hanya untuk
/// status dan tindakan.
///
/// Dua pintu: [TemaSidik.terang] dan [TemaSidik.gelap]. Semua komponen Material
/// (tombol, isian, chip, navigasi, dialog) ditema di sini, sehingga layar cukup
/// memakai widget bawaan atau komponen di `lib/widgets/` tanpa gaya sendiri.
/// Tokennya: `palet_sidik.dart` (warna mentah), `warna_sidik.dart` (status),
/// `spasi.dart`, `bentuk.dart`, `elevasi.dart`, `ukuran.dart`, `tipografi.dart`.
/// Nilai dari `docs/desain-ulang/tokens.json`.
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
    primary: PaletSidik.biru,
    onPrimary: PaletSidik.kartu,
    // Biru muda: ubin ikon, banner informasi, dan penanda pilihan aktif
    // (saringan, segmen, butir bilah), selalu dipadukan dengan tepi biru atau
    // indikator.
    primaryContainer: PaletSidik.biruMuda,
    onPrimaryContainer: PaletSidik.navy,
    // Putih bertinta biru: lencana jumlah di atas tombol biru, bulatan jumlah
    // di saringan terpilih, tombol sakelar nyala.
    secondary: PaletSidik.kartu,
    onSecondary: PaletSidik.biru,
    secondaryContainer: PaletSidik.latar,
    onSecondaryContainer: PaletSidik.navy,
    error: PaletSidik.galat,
    onError: PaletSidik.kartu,
    errorContainer: PaletSidik.koral,
    onErrorContainer: PaletSidik.galat,
    surface: PaletSidik.kartu,
    onSurface: PaletSidik.navy,
    onSurfaceVariant: PaletSidik.teksKedua,
    surfaceContainerLowest: PaletSidik.kartu,
    surfaceContainerLow: PaletSidik.kartu,
    surfaceContainer: PaletSidik.latar,
    surfaceContainerHigh: PaletSidik.latarTinggi,
    surfaceContainerHighest: PaletSidik.garis,
    outline: PaletSidik.garisTegas,
    outlineVariant: PaletSidik.garis,
    shadow: PaletSidik.bayangan,
    scrim: PaletSidik.bayangan,
    inverseSurface: PaletSidik.navy,
    onInverseSurface: PaletSidik.kartu,
    inversePrimary: PaletSidik.biruDiGelap,
    surfaceTint: Colors.transparent,
  );

  // Tema gelap: titik awal ("belum final"; belum ikut ditinjau di REVISI).
  static const ColorScheme _skemaGelap = ColorScheme(
    brightness: Brightness.dark,
    primary: PaletSidik.biruDiGelap,
    onPrimary: PaletSidik.latarGelap,
    primaryContainer: PaletSidik.navyLembut,
    onPrimaryContainer: PaletSidik.teksGelap,
    secondary: PaletSidik.latarGelap,
    onSecondary: PaletSidik.biruDiGelap,
    secondaryContainer: PaletSidik.permukaanTinggiGelap,
    onSecondaryContainer: PaletSidik.teksGelap,
    error: PaletSidik.koralTintaGelap,
    onError: PaletSidik.latarGelap,
    errorContainer: PaletSidik.gagalLatarGelap,
    onErrorContainer: PaletSidik.koralTintaGelap,
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
    inversePrimary: PaletSidik.biru,
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
    // Tombol: persegi bersudut 10 (utama, sekunder, dan teks).
    final bentukTombol = RoundedRectangleBorder(
      borderRadius: Bentuk.sudutTombol,
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

      // Kepala layar: setara latar halaman, tanpa bayangan dan tanpa garis
      // bawah (judul 18/24 di kiri; tombol kembali memakai ikon biasa).
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

      // Kartu datar: permukaan putih, sudut 16, garis halus, tanpa bayangan.
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
          padding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
          elevation: Elevasi.datar,
          shape: bentukTombol,
          textStyle: teks.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
          foregroundColor: skema.primary,
          backgroundColor: skema.surface,
          side: BorderSide(color: skema.outline),
          shape: bentukTombol,
          textStyle: teks.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AreaSentuh.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Spasi.lg),
          foregroundColor: skema.primary,
          shape: bentukTombol,
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

      // `NavigationBar` bawaan tidak dipakai di HP (bilah sendiri:
      // `BilahNavigasi`); tema ini hanya menjaga kalau suatu layar memakainya:
      // indikator biru muda, semua label tampil.
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
            fontWeight: s.contains(WidgetState.selected)
                ? TipografiSidik.beratLencana
                : TipografiSidik.beratLabel,
          ),
        ),
      ),
      // Rel samping (>= 600 dp): indikator biru muda di belakang ikon aktif.
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
          fontWeight: TipografiSidik.beratLencana,
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

      // Saringan: tidak aktif putih + tepi tegas, aktif biru muda + tepi biru
      // + teks navy. Warna label mengikuti keadaan terpilih.
      chipTheme: ChipThemeData(
        backgroundColor: skema.surface,
        selectedColor: skema.primaryContainer,
        checkmarkColor: skema.primary,
        side: BorderSide(color: skema.outline),
        labelStyle: teks.bodySmall?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? skema.onPrimaryContainer
                : skema.onSurface,
          ),
          fontWeight: TipografiSidik.beratLabel,
        ),
        secondaryLabelStyle: teks.bodySmall?.copyWith(
          color: skema.onPrimaryContainer,
          fontWeight: TipografiSidik.beratLabel,
        ),
        shape: RoundedRectangleBorder(borderRadius: Bentuk.sudutKapsul),
        padding: const EdgeInsets.symmetric(horizontal: Spasi.xs),
      ),
      // Pilihan tampilan (mis. Daftar | Arsip di tab Sertifikat): tinggi
      // sentuh 48 dp, segmen terpilih biru muda + teks navy.
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
                ? skema.primaryContainer
                : skema.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? skema.onPrimaryContainer
                : skema.onSurface,
          ),
        ),
      ),
      // Sakelar: nyala = rel biru + tombol putih; mati = rel latar + tepi
      // tegas + tombol teks kedua. Tema gelap: rel nyala berwarna terang
      // (primary), jadi tombolnya gelap (onPrimary). Ukuran bawaan Material 3.
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
