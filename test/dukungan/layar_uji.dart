// Ukuran layar uji. Navigasi utama berganti bentuk di lebar >= 600 dp (rel
// samping), jadi tes yang mengandalkan navigasi bawah harus berukuran HP.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layar HP [lebar] × [tinggi] dp pada kerapatan 1,0; dikembalikan otomatis.
void layarHp(WidgetTester tester, {double lebar = 360, double tinggi = 800}) {
  tester.view
    ..physicalSize = Size(lebar, tinggi)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Layar tablet 840 × 1200 dp.
void layarTablet(WidgetTester tester) =>
    layarHp(tester, lebar: 840, tinggi: 1200);
