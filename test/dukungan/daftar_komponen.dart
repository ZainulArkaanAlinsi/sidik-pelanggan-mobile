// Daftar komponen bersama "Jejak" (Paket 2) di `lib/widgets/`: berkas -> kelas
// publik. SATU sumber untuk tes pendaftaran (`test/tema/komponen_jejak_test.dart`)
// dan galeri render (`galeri_komponen.dart`). Komponen belum dipakai layar
// (Paket 3 memakainya per layar); daftar ini plus galeri yang mengimpor semuanya
// menjaga agar tak satu pun berkas komponen menjadi yatim tanpa pengimpor dan
// tanpa tes. Repo tidak punya pemeriksa berkas yatim di `tool/` maupun CI.
const daftarKomponenJejak = <String, List<String>>{
  'angka_hari': ['AngkaHari', 'AngkaKata'],
  'bagian': ['Bagian'],
  'baris_alat': ['BarisAlat'],
  'baris_sidik': ['BarisSidik'],
  'fakta': ['Fakta'],
  'garis_waktu_tahap': ['GarisWaktuTahap'],
  'jejak_tahap': ['JejakTahap'],
  'kalimat_utama': ['KalimatUtama', 'PotonganKalimat'],
  'keadaan_teks': ['KeadaanTeks', 'BannerDataTerakhir'],
  'kolom_cari_utuh': ['KolomCariUtuh'],
  'nomor_sidik': ['NomorSidik'],
  'panel_sidik': ['PanelSidik'],
  'peta_jatuh_tempo': ['PetaJatuhTempo', 'ZonaTempo'],
  'plat_nama': ['PlatNama'],
  'ringkasan_perhatian': ['RingkasanPerhatian'],
  'saringan_teks': ['SaringanTeks', 'PilihanSaringan'],
  'skala_tempo': ['SkalaTempo'],
  'stempel': ['Stempel'],
  'tautan_baris': ['TautanBaris'],
  'tik_paket': ['TikPaket', 'TahapTik'],
};
