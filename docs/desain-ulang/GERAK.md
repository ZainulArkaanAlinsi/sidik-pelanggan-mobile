# GERAK — animasi, formal dan hemat

Prinsip: gerak hanya menandai "ini baru datang" dan "ini yang kamu tekan".
Tidak ada denyut, kilau berulang, atau pegas memantul. Semua durasi dari
`AppMotion` yang sudah ada; tidak ada durasi baru. Semua lewat
`AppMotion.hormati(context, …)` supaya "kurangi gerak" di sistem mematikannya.

| Apa | Dari → ke | Durasi | Kurva | Tunda |
|---|---|---|---|---|
| Ubin masuk layar | opasitas 0→1, geser naik 12 dp | `sedang` 240 | `masuk` | `AppMotion.tunda(context, i)` = 35 ms × i, maks 210 |
| Visual alat | opasitas 0→1, skala 0,92→1 | 240 | `masuk` | 240 (setelah ubinnya) |
| Kapsul jatuh tempo | tinggi isi 0 → nilai (jangkar bawah) | 240 | `masuk` | 240 + 35 × kolom |
| Angka sorot (88, 124) | hitung 0 → nilai | 240 | `masuk` | bersama ubinnya; sekali per buka layar |
| Tekan tombol/ubin | skala 1 → 0,97 → 1 | `kilat` 120 | `masuk` | — |
| Pil dock dan segmen | geser ke butir baru | 240 | `masuk` | — |
| Sakelar, saringan terpilih | warna + posisi | 120 | `masuk` | — |
| Pindah halaman | `transisi_halaman.dart` yang ada | `halaman` 280 | — | — |
| Tarik-segarkan, kerangka memuat | tetap seperti sekarang (`kerangka.dart`) | — | — | — |

Mockup di canvas memakai angka yang sama (CSS `naik`, `muncul`, `tumbuh`,
`:active`), jadi yang terlihat saat tombol Play ditekan = yang dibangun.

Aturan:
- Animasi masuk hanya saat layar pertama kali dibangun, bukan tiap `setState`
  atau tiap data disegarkan (pakai `initState`, bukan `build`).
- Daftar panjang: hanya butir yang terlihat pertama (maks 6) yang berurutan;
  sisanya langsung tampil.
- Jangan animasikan teks status berubah warna tanpa ikon/kata ikut berubah.
- Tes: `MediaQuery(disableAnimations: true)` → semua langsung di keadaan akhir
  (tambahkan ke tes widget tiap komponen bergerak).

Potongan siap tempel: `flutter/gerak_bento.dart` (`MasukBerurutan`,
`TekanSkala`, `AngkaNaik`).
