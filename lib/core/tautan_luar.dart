/// Tautan yang boleh dibuka di aplikasi luar (WhatsApp, telepon, email, peta,
/// peramban). Aplikasi Pelanggan hanya MEMBUKA aplikasi lain lewat `url_launcher`;
/// ia tidak menulis apa pun ke server. Berkas ini satu-satunya tempat yang
/// memutuskan tautan MANA yang aman dibuka dan membangun tautannya.
///
/// Aturan:
/// - skema yang dibuka hanya `https`, `mailto`, dan `tel` ([bolehDibuka]);
///   `javascript:`, `file:`, `intent:`, `content:`, `http:` (tanpa enkripsi), dan
///   skema aplikasi lain ditolak. `wa.me` adalah `https`;
/// - tautan dari SERVER (WhatsApp, Instagram, LinkedIn, dokumen) dipakai hanya
///   bila `https`, punya host, tanpa `user:sandi@` ([web], [whatsapp]);
/// - tautan WhatsApp berpesan, `mailto`, `tel`, dan peta DIBANGUN di sini dari
///   nilai yang sudah divalidasi, bukan disambung ke URL dari server. Isi pesan
///   di-encode per komponen (`Uri.encodeComponent`: spasi `%20`, baris baru
///   `%0A`, `&`/`#`/`?`/`%` terlindung), jadi data alat tidak bisa menyelipkan
///   parameter lain.
///
/// Fungsi murni (tanpa Flutter, tanpa jaringan) supaya mudah diuji.
abstract final class TautanLuar {
  /// Skema yang boleh dibuka aplikasi.
  static const Set<String> skemaDiizinkan = {'https', 'mailto', 'tel'};

  /// Host WhatsApp yang diterima untuk tautan dari server.
  static const Set<String> _hostWhatsapp = {'wa.me', 'api.whatsapp.com'};

  /// Nomor internasional: 8 sampai 15 angka (E.164).
  static final RegExp _nomorWa = RegExp(r'^\d{8,15}$');

  /// Bagian lokal tanpa `?`, `&`, dan `#`: alamat disambung langsung ke
  /// `mailto:<alamat>?subject=...`, jadi tiga karakter itu bisa menyelipkan
  /// header (`sidik?bcc=evil@x.com`). Selebihnya tetap seperti sebelumnya.
  static final RegExp _emailValid = RegExp(
    r'^[A-Za-z0-9.!$%*+/=^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$',
  );

  /// Spasi, kontrol, kendali arah teks (bidi), dan lebar-nol: tidak boleh ada
  /// di tautan dari server maupun di kolom yang dimasukkan ke pesan.
  static final RegExp _tidakBoleh = RegExp(
    r'[\u0000- \u007F-\u009F​-‏ - ⁠-⁯﻿]',
  );

  /// `true` bila [uri] boleh diserahkan ke aplikasi luar.
  static bool bolehDibuka(Uri uri) {
    final skema = uri.scheme.toLowerCase();
    if (!skemaDiizinkan.contains(skema)) return false;
    if (skema == 'https') {
      return uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          !uri.toString().contains(_tidakBoleh);
    }
    // mailto / tel: ada tujuannya.
    if (skema == 'mailto' || skema == 'tel') {
      return uri.path.isNotEmpty && !uri.path.contains(_tidakBoleh);
    }
    return false;
  }

  /// Tautan web dari server (Instagram, LinkedIn, PDF ruang lingkup, dokumen
  /// hukum): `https` bertuan rumah saja. `null` bila kosong atau tidak aman
  /// (tombolnya disembunyikan).
  static Uri? web(String? mentah) {
    final t = mentah?.trim();
    if (t == null || t.isEmpty || t.contains(_tidakBoleh)) return null;
    final uri = Uri.tryParse(t);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
    return bolehDibuka(uri) ? uri : null;
  }

  /// Tautan WhatsApp dari server untuk "Chat dengan admin" tanpa pesan:
  /// `https` dan hostnya WhatsApp (`wa.me`, `api.whatsapp.com`).
  static Uri? whatsapp(String? mentah) {
    final uri = web(mentah);
    if (uri == null) return null;
    return _hostWhatsapp.contains(uri.host.toLowerCase()) ? uri : null;
  }

  /// Nomor (hanya angka, kode negara di depan) dari tautan `https://wa.me/<nomor>`;
  /// `null` untuk bentuk lain (mis. tautan bisnis `wa.me/message/...`), sehingga
  /// pesan terisi tidak bisa dibangun dan aplikasi memakai email.
  static String? nomorWhatsapp(String? mentah) {
    final uri = whatsapp(mentah);
    if (uri == null || uri.host.toLowerCase() != 'wa.me') return null;
    if (uri.pathSegments.length != 1) return null;
    final nomor = uri.pathSegments.first;
    return _nomorWa.hasMatch(nomor) ? nomor : null;
  }

  /// `https://wa.me/<nomor>?text=<pesan>`; `null` bila tautan server bukan
  /// bentuk `wa.me/<nomor>`. Satu-satunya parameter adalah `text`.
  static Uri? whatsappDenganPesan(String? tautanServer, String pesan) {
    final nomor = nomorWhatsapp(tautanServer);
    if (nomor == null) return null;
    return Uri.parse('https://wa.me/$nomor?text=${Uri.encodeComponent(pesan)}');
  }

  /// Alamat email yang bentuknya wajar; `null` bila kosong atau aneh.
  static String? alamatEmail(String? mentah) {
    final t = mentah?.trim();
    if (t == null || t.isEmpty || t.length > 254) return null;
    return _emailValid.hasMatch(t) ? t : null;
  }

  /// `mailto:<alamat>` dengan [subjek] dan [isi] (opsional) ter-encode per
  /// komponen. `null` bila [alamat] tidak wajar.
  static Uri? email(String? alamat, {String? subjek, String? isi}) {
    final a = alamatEmail(alamat);
    if (a == null) return null;
    final bagian = <String>[
      if (subjek != null) 'subject=${Uri.encodeComponent(subjek)}',
      if (isi != null) 'body=${Uri.encodeComponent(isi)}',
    ];
    return Uri.parse(
      'mailto:$a${bagian.isEmpty ? '' : '?${bagian.join('&')}'}',
    );
  }

  /// Teks telepon yang wajar: `+` hanya di depan, selebihnya angka, spasi, `-`,
  /// dan tanda kurung. Huruf, `;`, `,`, `#`, `*`, dan kendali arah teks ditolak
  /// (mis. "0822 6006 0037 ext 12" tidak boleh digabung jadi satu nomor lain).
  static final RegExp _teleponWajar = RegExp(r'^\+?[0-9 ()-]+$');

  /// `tel:<nomor>` dari teks telepon bebas ("0822 6006 0037", "+62 822-6006-0037");
  /// hanya angka dan `+` di depan yang dibawa. `null` bila kurang dari 6 angka
  /// atau teksnya memuat selain pemisah wajar ([_teleponWajar]).
  static Uri? telepon(String? mentah) {
    final t = mentah?.trim();
    if (t == null || t.isEmpty || !_teleponWajar.hasMatch(t)) return null;
    final awalPlus = t.startsWith('+');
    final angka = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (angka.length < 6 || angka.length > 15) return null;
    return Uri.parse('tel:${awalPlus ? '+' : ''}$angka');
  }

  /// Pencarian alamat di aplikasi peta (tautan Google Maps URLs yang resmi).
  /// `null` bila [alamat] kosong.
  static Uri? peta(String? alamat) {
    final t = alamat?.trim();
    if (t == null || t.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': t,
    });
  }
}
