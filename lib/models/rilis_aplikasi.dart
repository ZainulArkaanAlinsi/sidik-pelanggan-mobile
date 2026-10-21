/// Manifes rilis `versi-pelanggan.json`, aset GitHub Release yang ditulis
/// `tool/rilis.ps1`:
///
/// ```json
/// {"versi":"1.2.3","build":45,
///  "url":"https://github.com/<repo>/releases/download/<tag>/sidik-pelanggan.apk",
///  "sha256":"…64 hex…","ukuran":12345678,"wajib":false,"catatan":"…"}
/// ```
///
/// Yang dibandingkan dengan aplikasi terpasang adalah [build] (versionCode
/// Android), bukan teks versi: Android sendiri hanya mau memasang APK dengan
/// versionCode yang lebih tinggi, jadi itu satu-satunya angka yang menentukan
/// pembaruan bisa masuk atau tidak.
class RilisAplikasi {
  const RilisAplikasi({
    required this.versi,
    required this.build,
    required this.url,
    required this.sha256,
    this.ukuran,
    this.wajib = false,
    this.catatan,
  });

  /// `1.2.3` — untuk dibaca manusia.
  final String versi;

  /// versionCode — penentu urutan.
  final int build;

  /// Tautan langsung ke APK.
  final Uri url;

  /// SHA-256 APK, 64 hex huruf kecil. APK yang sidiknya beda TIDAK dipasang.
  final String sha256;

  /// Byte. `null` = tidak diketahui.
  final int? ukuran;

  /// Pembaruan yang tidak boleh ditunda: dialog yang tidak bisa ditutup.
  final bool wajib;

  final String? catatan;

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// `null` kalau manifesnya cacat — manifes yang tidak bisa dipercaya
  /// diperlakukan sama dengan "belum ada rilis", bukan galat di layar.
  ///
  /// [hostDiizinkan] = host yang boleh muncul di `url`. APK dari host lain
  /// ditolak walau sidiknya cocok: manifes dan APK harus dari tempat rilis
  /// yang sama.
  static RilisAplikasi? dariJson(
    Map<String, dynamic> j, {
    required Set<String> hostDiizinkan,
  }) {
    final versi = '${j['versi'] ?? ''}'.trim();
    final build = switch (j['build']) {
      final int b => b,
      final String s => int.tryParse(s.trim()),
      _ => null,
    };
    final url = Uri.tryParse('${j['url'] ?? ''}'.trim());
    final sha = '${j['sha256'] ?? ''}'.trim().toLowerCase();
    final ukuran = switch (j['ukuran']) {
      final int u when u > 0 => u,
      _ => null,
    };

    if (versi.isEmpty || build == null || build <= 0) return null;
    if (url == null || url.scheme != 'https') return null;
    if (!hostDiizinkan.contains(url.host)) return null;
    if (!_hex64.hasMatch(sha)) return null;

    final catatan = '${j['catatan'] ?? ''}'.trim();
    return RilisAplikasi(
      versi: versi,
      build: build,
      url: url,
      sha256: sha,
      ukuran: ukuran,
      wajib: j['wajib'] == true,
      catatan: catatan.isEmpty ? null : catatan,
    );
  }

  /// Lebih baru dari build terpasang? Build terpasang yang tidak terbaca
  /// (≤ 0) dianggap tidak bisa dibandingkan — lebih baik tidak menawarkan
  /// apa-apa daripada menawarkan pembaruan yang sama terus-menerus.
  bool lebihBaruDari(int buildTerpasang) =>
      buildTerpasang > 0 && build > buildTerpasang;

  /// `25 MB` untuk tombol unduh; `null` kalau ukuran tidak diketahui.
  String? get ukuranMb {
    final b = ukuran;
    if (b == null) return null;
    final mb = b / 1024 / 1024;
    return mb < 1 ? '< 1 MB' : '${mb.round()} MB';
  }
}
