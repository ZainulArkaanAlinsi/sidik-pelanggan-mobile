package id.ptsidik.sidik_pelanggan

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Satu pintu ke setelan notifikasi aplikasi ini di HP (banner
        // "Notifikasi mati … [Nyalakan]"). Sesudah dua kali ditolak, Android
        // 13+ tidak menampilkan dialog izin lagi; satu-satunya jalan
        // menyalakannya kembali adalah layar setelan ini.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sidik_pelanggan/setelan")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bukaSetelanNotifikasi" -> result.success(bukaSetelanNotifikasi())
                    else -> result.notImplemented()
                }
            }
    }

    private fun bukaSetelanNotifikasi(): Boolean =
        try {
            val intent =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(Uri.fromParts("package", packageName, null))
                }
            startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: Exception) {
            false
        }
}
