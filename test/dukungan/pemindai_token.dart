import 'dart:convert';
import 'dart:io';

/// Pemindai "token-only" untuk gerbang desain Pelanggan.
///
/// Menghitung nilai liar (warna, ukuran huruf, radius, tinggi tombol yang
/// ditulis langsung di kode) per berkas di `lib/`. Dipakai
/// `test/tema/token_only_test.dart` untuk ratchet DUA ARAH: hitungan
/// dibandingkan dengan baseline, dan tes gagal bila ada berkas BARU, hitungan
/// NAIK, atau hitungan TURUN tanpa baseline ikut diturunkan.
///
/// Komentar dibuang dulu supaya catatan seperti "(#585E67)" di docblock tidak
/// dihitung sebagai pelanggaran.
///
/// Pemindai ini membaca teks, bukan pohon sintaks. Ia menangkap bentuk yang
/// umum (literal, ekspresi angka murni, variabel yang di berkas yang sama
/// diisi literal angka), bukan semua cara menyelipkan angka. Cakupannya
/// dipatok di `token_only_test.dart` (daftar [dilewati], jumlah berkas minimum).
class PemindaiToken {
  const PemindaiToken._();

  /// Kategori yang dijaga, urut seperti di berkas baseline.
  ///
  /// - `hex_mentah`          literal `0xAARRGGBB`/`0xRRGGBB` (juga `0X`) atau
  ///                         `#RRGGBB(AA)`
  /// - `color_0x`            `Color(0x...)` (juga `Color(0X...)`)
  /// - `warna_konstruktor`   `Color.fromARGB/fromRGBO/from(`, `Color(<desimal>)`,
  ///                         `HSLColor`/`HSVColor`, `CupertinoColors`
  /// - `colors_mentah`       `Colors.xxx` selain `transparent`
  /// - `fontsize_kecil`      `fontSize:` yang nilainya < 12, dari literal,
  ///                         ekspresi angka murni (`9 * 1.0`), variabel yang di
  ///                         berkas yang sama diisi literal angka, atau ekspresi
  ///                         campuran yang memuat angka pengecil (`k ? 9 : 14`,
  ///                         `t.fontSize! * 0.5`, `x - 3`; `x * 1.2` dan `x + 2`
  ///                         tidak)
  /// - `radius_literal`      `Radius.circular(...)`/`BorderRadius.circular(...)`
  ///                         atau argumen `radius:` di pemanggil widget
  ///                         (`Kerangka(radius: 7)`) dengan angka (literal,
  ///                         ekspresi murni, atau variabel berisi literal)
  /// - `radius_ekspresi`     idem, dengan ekspresi campuran (`Bentuk.kartu + 4`,
  ///                         `a ? b : 8`): bukan token dan tak bisa dibuktikan
  ///                         ada di set radius. Nama murni (`radius`,
  ///                         `Bentuk.kontrol`) lolos.
  /// - `tinggi_tombol_kecil` `minimumSize`/`fixedSize` dengan tinggi literal
  ///                         < 48, `SizedBox(height: <48, child: <tombol>)`
  ///                         (urutan argumen bebas), dan
  ///                         `ConstrainedBox(constraints: ...maxHeight < 48)` yang
  ///                         langsung membungkus tombol
  static const kategori = <String>[
    'hex_mentah',
    'color_0x',
    'warna_konstruktor',
    'colors_mentah',
    'fontsize_kecil',
    'radius_literal',
    'radius_ekspresi',
    'tinggi_tombol_kecil',
  ];

  /// Kategori warna tidak berlaku di satu berkas ini: di sanalah nilai mentah
  /// memang harus ditulis. Lebih sempit daripada seluruh `lib/core/tema/`, sama
  /// dengan aturan lama di `tema_sidik_test.dart` ("Color(0x hanya di
  /// palet_sidik.dart").
  static const _sumberWarna = 'lib/core/tema/palet_sidik.dart';
  static const _kategoriWarna = {
    'hex_mentah',
    'color_0x',
    'warna_konstruktor',
    'colors_mentah',
  };

  /// Radius didefinisikan di satu berkas ini (`static const double kecil = 4;`
  /// lalu `BorderRadius.circular(kecil)`), jadi kategori radius tidak berlaku
  /// di sana. Angka di berkas ini dijaga `token_tema_test.dart` (set radius).
  static const _sumberRadius = 'lib/core/tema/bentuk.dart';
  static const _kategoriRadius = {'radius_literal', 'radius_ekspresi'};

  /// Berkas yang TIDAK dipindai, dengan alasannya. Kunci berakhiran `/` = awalan
  /// folder; selain itu = akhiran nama berkas. Pelanggan tidak punya kode
  /// hasil generator di `lib/`, jadi daftarnya KOSONG dan semua berkas
  /// dipindai. Menambah entri di sini harus disertai perubahan di
  /// `token_only_test.dart` (daftar yang diharapkan), jadi tidak bisa terjadi
  /// diam-diam.
  static const dilewati = <String, String>{};

  static bool dilewatiBerkas(String jalur) => dilewati.keys.any(
    (k) => k.endsWith('/') ? jalur.startsWith(k) : jalur.endsWith(k),
  );

  static final _hex = RegExp(
    r'\b0[xX][0-9A-Fa-f]{6,8}\b|#(?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})\b',
  );
  static final _color0x = RegExp(r'\bColor\(\s*0[xX]');
  static final _warnaKonstruktor = RegExp(
    r'\bColor\.from(?:ARGB|RGBO)?\(|\bColor\(\s*(?!0[xX])\d|\bHSLColor\b|\bHSVColor\b|\bCupertinoColors\.',
  );
  static final _colors = RegExp(r'\bColors\.(?!transparent\b)[A-Za-z_]\w*');
  static final _fontSize = RegExp(r'\bfontSize:\s*');
  static final _radius = RegExp(r'Radius\.circular\(');
  static final _radiusArg = RegExp(r'\bradius:\s*');
  static final _ukuranTombol = RegExp(r'\b(?:minimumSize|fixedSize)\s*:\s*');
  static final _kotakTombol = RegExp(r'\b(SizedBox|ConstrainedBox)\(');
  static final _tombol = RegExp(
    r'^(?:const\s+)?(?:FilledButton|OutlinedButton|TextButton|ElevatedButton|IconButton|TombolSidik)\b',
  );
  static final _namaArg = RegExp(r'^\s*(\w+)\s*:\s*([\s\S]*)$');
  static final _batasTinggi = RegExp(r'\b(?:maxHeight|height):\s*');
  static final _angka = RegExp(r'(?<![\w.$])(\d+(?:\.\d+)?)');
  static final _jalurNama = RegExp(r'^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*$');
  static final _nama = RegExp(r'^[A-Za-z_]\w*$');
  static final _deklarasi = RegExp(
    r'\b(?:const|final)\s+(?:double|num|int)?\s*([A-Za-z_]\w*)\s*=\s*([^;=]+);',
  );

  /// Hitung pelanggaran di [sumber] (isi satu berkas) per kategori.
  static Map<String, int> hitung(String sumber, {String jalur = ''}) {
    final kode = buangKomentar(sumber);
    final diSumberWarna = jalur == _sumberWarna;

    // Variabel yang di berkas ini diisi literal angka: nama -> nilai.
    final literal = <String, double>{};
    for (final m in _deklarasi.allMatches(kode)) {
      final v = evaluasi(m.group(2)!);
      if (v != null) literal[m.group(1)!] = v;
    }
    double? nilai(String arg) {
      final a = arg.trim();
      return evaluasi(a) ?? (_nama.hasMatch(a) ? literal[a] : null);
    }

    var fontKecil = 0;
    for (final m in _fontSize.allMatches(kode)) {
      final arg = _nilaiSetelah(kode, m.end);
      final v = nilai(arg);
      if (v != null ? v < 12 : _adaLiteralMengecil(arg)) fontKecil++;
    }

    var radiusAngka = 0;
    var radiusEkspresi = 0;
    for (final m in _radius.allMatches(kode)) {
      final arg = _isiKurung(kode, m.end - 1)?.trim();
      if (arg == null || arg.isEmpty) continue;
      if (nilai(arg) != null) {
        radiusAngka++;
      } else if (!_jalurNama.hasMatch(arg)) {
        radiusEkspresi++;
      }
    }

    // Radius lewat parameter widget (`Kerangka(radius: 7)`): angka di pemanggil
    // sama saja dengan angka di `BorderRadius.circular(7)`.
    for (final m in _radiusArg.allMatches(kode)) {
      final arg = _nilaiSetelah(kode, m.end).trim();
      if (arg.isEmpty) continue;
      if (nilai(arg) != null) {
        radiusAngka++;
      } else if (!_jalurNama.hasMatch(arg)) {
        radiusEkspresi++;
      }
    }

    var tombolKecil = 0;
    for (final m in _ukuranTombol.allMatches(kode)) {
      final h = _tinggiDariSize(_nilaiSetelah(kode, m.end), nilai);
      if (h != null && h < 48) tombolKecil++;
    }
    // Tombol yang dibungkus `SizedBox(height: <48)` atau
    // `ConstrainedBox(constraints: ...maxHeight/height < 48)`, urutan argumen
    // bebas. Bungkus lain (Center, Padding) di antaranya tidak ikut terbaca.
    for (final m in _kotakTombol.allMatches(kode)) {
      final isi = _isiKurung(kode, m.end - 1);
      if (isi == null) continue;
      final arg = <String, String>{};
      for (final bagian in _pisahTingkatNol(isi)) {
        final k = _namaArg.firstMatch(bagian);
        if (k != null) arg[k.group(1)!] = k.group(2)!.trim();
      }
      final anak = arg['child'];
      if (anak == null || !_tombol.hasMatch(anak)) continue;
      final double? tinggi;
      if (m.group(1) == 'SizedBox') {
        tinggi = nilai(arg['height'] ?? '');
      } else {
        tinggi = _tinggiBatas(arg['constraints'] ?? '', nilai);
      }
      if (tinggi != null && tinggi < 48) tombolKecil++;
    }

    final hasil = <String, int>{
      'hex_mentah': _hex.allMatches(kode).length,
      'color_0x': _color0x.allMatches(kode).length,
      'warna_konstruktor': _warnaKonstruktor.allMatches(kode).length,
      'colors_mentah': _colors.allMatches(kode).length,
      'fontsize_kecil': fontKecil,
      'radius_literal': radiusAngka,
      'radius_ekspresi': radiusEkspresi,
      'tinggi_tombol_kecil': tombolKecil,
    };
    if (diSumberWarna) {
      for (final k in _kategoriWarna) {
        hasil[k] = 0;
      }
    }
    if (jalur == _sumberRadius) {
      for (final k in _kategoriRadius) {
        hasil[k] = 0;
      }
    }
    return hasil;
  }

  /// True bila ekspresi fontSize yang tak bisa dihitung penuh (campuran nama
  /// dan angka) memuat angka yang bisa membuat huruf < 12 sp. Konservatif:
  /// angka telanjang < 12 (`k ? 9 : 14`), faktor `* x` dengan x < 1
  /// (`t.fontSize! * 0.5`), pembagi `/ x` dengan x > 1, dan pengurang `- x`.
  /// Penambah `+ x` dan faktor >= 1 tidak dihitung (tidak mengecilkan). Nama
  /// murni tanpa angka tidak dihitung: nilainya tak bisa dibuktikan dari teks.
  static bool _adaLiteralMengecil(String ekspresi) {
    for (final m in _angka.allMatches(ekspresi)) {
      final v = double.parse(m.group(1)!);
      final sebelum = ekspresi.substring(0, m.start).trimRight();
      final op = sebelum.isEmpty ? '' : sebelum[sebelum.length - 1];
      if (op == '*') {
        if (v < 1) return true;
      } else if (op == '/') {
        if (v > 1) return true;
      } else if (op == '+') {
        continue;
      } else if (v < 12) {
        return true;
      }
    }
    return false;
  }

  /// Batas tinggi terkecil yang terbaca dari argumen `constraints:`
  /// (`BoxConstraints(maxHeight: 30)`, `tightFor(height: 30)`,
  /// `tight(Size(w, 30))`). `minHeight` tidak membatasi dari atas: diabaikan.
  static double? _tinggiBatas(String c, double? Function(String) nilai) {
    double? terkecil;
    void catat(double? v) {
      if (v != null && (terkecil == null || v < terkecil!)) terkecil = v;
    }

    for (final m in _batasTinggi.allMatches(c)) {
      catat(nilai(_nilaiSetelah(c, m.end)));
    }
    if (c.contains('.tight(')) catat(_tinggiDariSize(c, nilai));
    return terkecil;
  }

  /// Tinggi dari `Size(w, h)`, `Size.fromHeight(h)`, atau `Size.square(n)` di
  /// dalam [seg] (boleh dibungkus `WidgetStatePropertyAll(...)`).
  static double? _tinggiDariSize(String seg, double? Function(String) nilai) {
    for (final pola in [
      (RegExp(r'Size\.fromHeight\('), 0),
      (RegExp(r'Size\.square\('), 0),
      (RegExp(r'(?<![\w.])Size\('), 1),
    ]) {
      final m = pola.$1.firstMatch(seg);
      if (m == null) continue;
      final isi = _isiKurung(seg, m.end - 1);
      if (isi == null) return null;
      final bagian = _pisahTingkatNol(isi);
      if (pola.$2 >= bagian.length) return null;
      return nilai(bagian[pola.$2]);
    }
    return null;
  }

  /// Isi tanda kurung yang dibuka pada indeks [buka] (karakter `(`).
  static String? _isiKurung(String s, int buka) {
    var dalam = 0;
    for (var i = buka; i < s.length; i++) {
      final c = s[i];
      if (c == '(') {
        dalam++;
      } else if (c == ')') {
        dalam--;
        if (dalam == 0) return s.substring(buka + 1, i);
      }
    }
    return null;
  }

  /// Nilai argumen bernama yang mulai di [mulai], sampai `,` `)` `}` `]` `;`
  /// di kedalaman nol.
  static String _nilaiSetelah(String s, int mulai) {
    var dalam = 0;
    for (var i = mulai; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') {
        dalam++;
      } else if (c == ')' || c == ']' || c == '}') {
        if (dalam == 0) return s.substring(mulai, i);
        dalam--;
      } else if ((c == ',' || c == ';') && dalam == 0) {
        return s.substring(mulai, i);
      }
    }
    return s.substring(mulai);
  }

  static List<String> _pisahTingkatNol(String s) {
    final bagian = <String>[];
    var dalam = 0;
    var awal = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') dalam++;
      if (c == ')' || c == ']' || c == '}') dalam--;
      if (c == ',' && dalam == 0) {
        bagian.add(s.substring(awal, i));
        awal = i + 1;
      }
    }
    bagian.add(s.substring(awal));
    return bagian;
  }

  /// Hitung ekspresi angka murni (`9 * 1.0`, `(14 * 0.8)`, `-3`). Mengembalikan
  /// `null` bila ada yang bukan angka (nama, pemanggilan, `?:`, dan seterusnya).
  static double? evaluasi(String teks) {
    final s = teks.replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return null;
    var i = 0;
    var gagal = false;

    late double Function() tambah;
    late double Function() kali;
    late double Function() unari;

    unari = () {
      if (i < s.length && (s[i] == '-' || s[i] == '+')) {
        final negatif = s[i++] == '-';
        final v = unari();
        return negatif ? -v : v;
      }
      if (i < s.length && s[i] == '(') {
        i++;
        final v = tambah();
        if (i < s.length && s[i] == ')') {
          i++;
        } else {
          gagal = true;
        }
        return v;
      }
      final m = RegExp(r'\d+(?:\.\d+)?|\.\d+').matchAsPrefix(s, i);
      if (m == null) {
        gagal = true;
        return 0;
      }
      i = m.end;
      return double.parse(m.group(0)!);
    };
    kali = () {
      var v = unari();
      while (i < s.length && (s[i] == '*' || s[i] == '/')) {
        final op = s[i++];
        final r = unari();
        v = op == '*' ? v * r : (r == 0 ? double.nan : v / r);
      }
      return v;
    };
    tambah = () {
      var v = kali();
      while (i < s.length && (s[i] == '+' || s[i] == '-')) {
        final op = s[i++];
        final r = kali();
        v = op == '+' ? v + r : v - r;
      }
      return v;
    };

    final v = tambah();
    if (gagal || i != s.length || v.isNaN) return null;
    return v;
  }

  /// Pindai seluruh `lib/`. Hasil: kategori -> {jalur: hitungan} (hanya berkas
  /// dengan hitungan > 0) dan daftar jalur yang dipindai. Jalur memakai `/`.
  static HasilPindai pindai({String akar = 'lib'}) {
    final hasil = {for (final k in kategori) k: <String, int>{}};
    final dipindai = <String>[];
    final berkas =
        Directory(akar)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in berkas) {
      final jalur = f.path.replaceAll('\\', '/');
      if (dilewatiBerkas(jalur)) continue;
      dipindai.add(jalur);
      final hitungan = hitung(f.readAsStringSync(), jalur: jalur);
      for (final k in kategori) {
        final n = hitungan[k]!;
        if (n > 0) hasil[k]![jalur] = n;
      }
    }
    return HasilPindai(hasil, dipindai);
  }

  /// Serialisasi baseline dengan urutan kunci tetap supaya diff-nya terbaca.
  /// `_ringkasan` memuat jumlah berkas dipindai dan total per kategori: ini
  /// bukan pengaman (bisa diedit tangan), tetapi membuat KENAIKAN baseline
  /// kelihatan di diff dan bisa disebut di PR.
  static String keJson(HasilPindai data, {required String catatan}) {
    final peta = <String, Object>{'_catatan': catatan};
    peta['_ringkasan'] = {
      'berkas_dipindai': data.dipindai.length,
      'total': {
        for (final k in kategori)
          k: (data.hitungan[k] ?? const <String, int>{}).values.fold<int>(
            0,
            (a, b) => a + b,
          ),
      },
    };
    for (final k in kategori) {
      final isi = data.hitungan[k] ?? const <String, int>{};
      final urut = isi.keys.toList()..sort();
      peta[k] = {for (final j in urut) j: isi[j]!};
    }
    return '${const JsonEncoder.withIndent('  ').convert(peta)}\n';
  }

  /// Baca baseline dari JSON. Kategori yang tidak ada di berkas tidak muncul di
  /// hasil (kategori baru yang belum dibekukan). Kunci berawalan `_` metadata.
  static Baseline dariJson(String json) {
    final mentah = jsonDecode(json) as Map<String, dynamic>;
    final ringkasan = (mentah['_ringkasan'] as Map<String, dynamic>?) ?? {};
    return Baseline(
      {
        for (final k in kategori)
          if (mentah[k] != null)
            k: {
              for (final e in (mentah[k] as Map<String, dynamic>).entries)
                e.key: e.value as int,
            },
      },
      berkasDipindai: ringkasan['berkas_dipindai'] as int?,
      total: {
        for (final e
            in ((ringkasan['total'] as Map<String, dynamic>?) ?? {}).entries)
          e.key: e.value as int,
      },
    );
  }

  /// Buang komentar `//`, `///`, dan `/* */` tanpa menyentuh isi string.
  /// Baris baru dipertahankan supaya nomor baris tidak bergeser.
  static String buangKomentar(String s) {
    final out = StringBuffer();
    final n = s.length;
    var i = 0;
    while (i < n) {
      final c = s[i];
      final berikut = i + 1 < n ? s[i + 1] : '';
      if (c == '/' && berikut == '/') {
        while (i < n && s[i] != '\n') {
          i++;
        }
        continue;
      }
      if (c == '/' && berikut == '*') {
        var dalam = 1;
        i += 2;
        while (i < n && dalam > 0) {
          if (s[i] == '/' && i + 1 < n && s[i + 1] == '*') {
            dalam++;
            i += 2;
          } else if (s[i] == '*' && i + 1 < n && s[i + 1] == '/') {
            dalam--;
            i += 2;
          } else {
            if (s[i] == '\n') out.write('\n');
            i++;
          }
        }
        continue;
      }
      if (c == '\'' || c == '"') {
        final mentah = i > 0 && s[i - 1] == 'r';
        final tiga = s.startsWith(c * 3, i);
        final penutup = tiga ? c * 3 : c;
        out.write(penutup);
        i += penutup.length;
        while (i < n && !s.startsWith(penutup, i)) {
          if (!mentah && s[i] == '\\' && i + 1 < n) {
            out.write(s[i]);
            out.write(s[i + 1]);
            i += 2;
            continue;
          }
          if (!tiga && s[i] == '\n') break; // string satu baris tak berpenutup
          out.write(s[i]);
          i++;
        }
        if (i < n && s.startsWith(penutup, i)) {
          out.write(penutup);
          i += penutup.length;
        }
        continue;
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }
}

/// Hasil pindai: hitungan per kategori per berkas, dan berkas yang dipindai.
class HasilPindai {
  const HasilPindai(this.hitungan, this.dipindai);
  final Map<String, Map<String, int>> hitungan;
  final List<String> dipindai;
}

/// Baseline yang dibaca dari JSON.
class Baseline {
  const Baseline(this.hitungan, {this.berkasDipindai, this.total = const {}});
  final Map<String, Map<String, int>> hitungan;
  final int? berkasDipindai;
  final Map<String, int> total;
}
