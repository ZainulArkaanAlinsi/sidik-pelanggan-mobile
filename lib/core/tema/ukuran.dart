/// Token ukuran ikon dan area sentuh (dp).
abstract final class UkuranIkon {
  /// Ikon di dalam chip dan baris keterangan.
  static const double kecil = 16;

  /// Ikon standar di baris, tombol, dan navigasi.
  static const double sedang = 24;

  /// Ikon di ubin kartu dan kepala layar.
  static const double besar = 32;

  /// Ilustrasi keadaan kosong dan galat.
  static const double ilustrasi = 48;

  /// Ikon di dalam stempel status (Bento Lab).
  static const double stempel = 14;

  /// Ikon di tombol bulat 44 dan 48 dan di kolom cari (Bento Lab).
  static const double tombol = 20;

  /// Ikon di tombol bulat 52, aksi di ubin (Bento Lab).
  static const double tombolBesar = 22;
}

/// Ukuran minimum area sentuh (pedoman Material dan WCAG 2.5.8: 48 dp).
abstract final class AreaSentuh {
  static const double minimum = 48;
}

/// Tinggi baris dan tombol (REVISI 16 Nov: ringkas, tombol 44-48).
abstract final class UkuranBaris {
  /// Tinggi minimum baris daftar dua sampai empat baris teks.
  static const double minimum = 64;

  /// Tombol utama: satu per bagian, dijangkau ibu jari (48; revisi 44-48).
  static const double tombolUtama = 48;

  /// Lebar kolom angka-hari di awal baris (diskalakan dengan huruf).
  static const double kolomAngka = 48;
}

/// Tik pada jejak tahap dan peta jatuh tempo (motif skala, dipakai hemat).
abstract final class UkuranTik {
  static const double tinggi = 6;
  static const double tinggiSekarang = 12;
  static const double jarak = 4;

  /// Simpul persegi pada garis waktu tegak (`GarisWaktuTahap`).
  static const double simpul = 14;

  /// Simpul tahap "sekarang": simpul 14 + lingkar 4 di tiap sisi = 22.
  static const double simpulSekarang = 22;

  /// Tebal batang penghubung simpul, tik jadwal, dan bingkai simpul belum.
  static const double batang = 2;

  /// Tebal lingkar simpul "sekarang".
  static const double lingkar = 4;

  /// Tebal garis bawah pilihan terpilih pada `SaringanTeks`.
  static const double garisBawah = 3;

  /// Tinggi tik jadwal yang memotong batang pada `SkalaTempo`.
  static const double penanda = 24;

  /// Jumlah tik per alat paling banyak; di atasnya `TikPaket` jatuh ke satu
  /// batang bersegmen supaya tik tidak lebih sempit dari jaraknya.
  static const int tikPaketMaksimum = 24;
}

/// Batas skala huruf sistem untuk teks besar dan nomor.
abstract final class SkalaHuruf {
  /// Teks 28 sp ke atas (kalimat utama, angka-hari) dijepit sampai kali ini
  /// terhadap skala huruf sistem; teks bacaan menskala penuh. 32 sp x 1,3 =
  /// 42 sp memakan empat baris di 320 dp.
  static const double batasBesar = 1.15;

  /// Nomor (order, sertifikat, seri) boleh mengecil agar satu baris, tetapi
  /// tidak di bawah ukuran efektif ini (sp); di bawahnya nomor membungkus di
  /// garis miring atau strip, tidak pernah putus di tengah angka.
  static const double nomorMinimum = 12;
}

// ── Ukuran komponen (docs/desain-ulang/tokens.json, diselaraskan ke REVISI 16
// Nov 2026) ── dp pada layar rujukan 390. Tinggi ubin adalah MINIMUM: pada
// skala huruf sistem di atas 1,0 ubin tumbuh. Pakai
// `ConstrainedBox(minHeight:)`, jangan `SizedBox(height:)`. Komponen baru
// membaca angkanya dari sini.

/// Kontrol: tombol bulat, saringan, segmen, kolom cari, sakelar, stempel.
abstract final class UkuranKontrol {
  /// Tombol bulat kecil, di dalam kolom cari (biru; area ketuk tetap 48).
  static const double tombolBulatKecil = 36;

  /// Tombol bulat di kepala layar (kembali, putih).
  static const double tombolBulat = 48;

  /// Tombol bulat aksi di ubin (kuning/navy).
  static const double tombolBulatBesar = 52;

  /// Saringan (tinggi visual; area ketuk tetap 48); jumlahnya bulat 24.
  static const double saringan = 40;

  /// Jumlah di dalam saringan (bulat).
  static const double jumlahSaringan = 24;

  /// Segmen dua pilihan: tinggi luar (padding 4) dan tinggi pilihan dalam.
  static const double segmenLuar = 48;
  static const double segmenDalam = 40;

  /// Kolom cari (tombol bulat 36 di kanan; area ketuknya 48).
  static const double kolomCari = 48;

  /// Sakelar: rel 56 x 36, tombol 28, padding 4.
  static const double sakelarLebar = 56;
  static const double sakelarTinggi = 36;
  static const double sakelarTombol = 28;

  /// Lencana status: setinggi 24 (radius [Bentuk.stempel]).
  static const double stempel = 24;

  /// Jarak ikon ke kata di lencana status (4).
  static const double stempelJarak = 4;

  /// Tombol bulat di ubin menu (40) dan lencana jumlah di tombol utama (28).
  static const double tombolBulatUbin = 40;
  static const double lencanaTombol = 28;

  /// Tombol utama dengan lencana: padding awal 20 (akhir [Spasi.sm]).
  static const double tombolUtamaAwal = 20;

  /// Tombol sekunder: padding mendatar 20.
  static const double tombolSekunder = 20;

  /// Saringan: padding akhir 4 bila ada jumlah (awal [Spasi.lg]); jarak
  /// antar-saringan [Spasi.sm].
  static const double saringanAkhir = 4;

  /// Segmen: padding luar dan jarak antar-segmen 4.
  static const double segmenPadding = 4;

  /// Kolom cari: padding awal 16 dan akhir 6 (tombol bulat 36 di kanan).
  static const double kolomCariAwal = 16;
  static const double kolomCariAkhir = 6;

  /// Panel berisi baris: padding 4 di semua sisi.
  static const double panelBaris = 4;
}

/// Cincin fokus papan ketik: di LUAR isi, dengan celah, supaya tidak menutupi
/// isi dan tidak menggeser tata letak. Warnanya `ColorScheme.primary` (navy di
/// terang, biru muda di gelap): jauh di atas 3:1 terhadap halaman di dua tema.
abstract final class UkuranFokus {
  /// Celah antara isi dan cincin.
  static const double celah = 2;

  /// Tebal garis cincin.
  static const double tebal = 2;

  /// Jarak luar cincin dari tepi isi (celah + tebal).
  static const double jarakLuar = celah + tebal;
}

/// Baris, ubin, dan grafik.
abstract final class UkuranUbin {
  /// Baris menu: tinggi 56, ubin ikon 40.
  static const double barisMenu = 56;
  static const double ubinIkon = 40;

  /// Baris daftar: sama dengan [UkuranBaris.minimum] (64).
  static const double barisDaftar = 64;

  /// Ubin alat: 144 (Beranda 160). Minimum; tumbuh bersama isi dan huruf.
  static const double alat = 144;
  static const double alatBeranda = 160;

  /// Ubin pasangan (2 kolom, 132) dan ubin menu (2 kolom, 124).
  static const double pasangan = 132;
  static const double menu = 124;

  /// Kapsul jatuh tempo: rel 100, isi paling pendek 40.
  static const double kapsulRel = 100;
  static const double kapsulMin = 40;

  /// Avatar inisial: 48 (daftar) dan 88 (profil).
  static const double avatar = 48;
  static const double avatarBesar = 88;

  /// Padding dalam ubin alat dan panel isi bebas (16, sama dengan
  /// [Spasi.lg]); ubin pasangan dan menu memakai [Spasi.lg] juga.
  static const double paddingAlat = 16;

  /// Lebar judul ubin menu paling banyak (dua baris).
  static const double judulMenuMaks = 100;

  /// Avatar kecil di tumpukan ubin menu.
  static const double avatarUbin = 40;
}

/// Bilah navigasi bawah solid (HP, di bawah [Spasi.batasLebar]; REVISI-2
/// butir 13): permukaan putih selebar layar, garis tipis di atasnya, semua
/// menu berlabel. Tinggi di bawah ini TIDAK termasuk tepi sistem (gesture bar),
/// yang ditambahkan di bawahnya di dalam permukaan yang sama.
abstract final class UkuranBilah {
  /// Tinggi isi bilah (ikon + label), minimum; tumbuh bersama huruf.
  static const double tinggi = 64;

  /// Ikon butir.
  static const double ikon = 24;

  /// Indikator aktif di belakang ikon (biru muda): 56 x 32.
  static const double indikatorLebar = 56;
  static const double indikatorTinggi = 32;

  /// Huruf label butir mengikuti skala sistem paling banyak sampai kali ini;
  /// bila masih tidak muat, label mengecil (tidak pernah terpotong).
  static const double skalaLabel = 1.3;
}

/// Visual alat (gambar milik sendiri, kanvas 240 x 240).
abstract final class UkuranVisual {
  static const double alat = 160;
  static const double alatBeranda = 176;
  static const double ubinKecil = 112;

  /// Visual di ubin menu.
  static const double ubinMenu = 100;

  /// Visual ubin alat di lebar < [Spasi.batasKompak].
  static const double alatKompak = 120;

  /// Visual ubin alat keluar dari tepi kanan 10 dan tepi bawah 20.
  static const double keluarSamping = 10;
  static const double keluarBawah = 20;

  /// Visual ubin pasangan dan menu keluar 10 di kedua sisi.
  static const double keluarKecil = 10;
}

/// Layar auth (Sambutan, Masuk, Lupa sandi, Terima undangan): susunan E0 Masuk.
/// Kepala biru muda di atas, plat logo putih di dalamnya, kartu putih yang
/// menumpang ke tepi bawah kepala. Diperkecil oleh REVISI 16 Nov ("kurangi
/// bidang berwarna dan logo besar"); penyusunan ulang layarnya di PR berikut.
abstract final class UkuranAuth {
  /// Tinggi kepala paling kecil di layar akar (Sambutan, Masuk), diukur dari
  /// tepi atas layar sampai tepi bawah warna kepala (kartu ikut menumpang
  /// di dalamnya). Tumbuh bila isi (huruf besar, status bar) lebih tinggi.
  static const double hero = 240;

  /// Kartu menumpang ke dalam kepala sedalam ini.
  static const double kartuTumpang = 24;

  /// Plat logo putih di layar akar; logo di dalamnya = plat - 2 x `Spasi.lg`.
  static const double platLogo = 80;

  /// Plat logo di layar anak (Lupa sandi, Terima undangan): kepala pendek.
  static const double platLogoAnak = 64;
}
