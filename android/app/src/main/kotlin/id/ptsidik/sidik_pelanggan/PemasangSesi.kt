package id.ptsidik.sidik_pelanggan

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.io.File

/**
 * Memasang APK pembaruan lewat `PackageInstaller` (porting dari
 * `PemasangSesi.kt` aplikasi lab `sidik-mobile-ocr-tt`).
 *
 * Membuka APK lewat intent VIEW selalu memunculkan layar "Install" DAN yang
 * tercatat sebagai pemasang tetap pemasang sistem. Android 12+ hanya mengizinkan
 * pembaruan tanpa layar konfirmasi (`USER_ACTION_NOT_REQUIRED`) kalau yang
 * memasang adalah "installer of record" paket itu sendiri. Pemasangan pertama
 * lewat sesi ini masih minta satu ketukan; sesudahnya aplikasi ini tercatat
 * sebagai pemasangnya. Sesi hanya dimulai dari ketukan "Perbarui"/"Pasang"
 * pelanggan — tidak pernah dari latar.
 *
 * APK yang sampai di sini sudah dicocokkan SHA-256-nya di sisi Dart, dan
 * Android sendiri menolak pembaruan yang ditandatangani kunci berbeda.
 */
object PemasangSesi {
    private const val TAG = "PemasangSesi"

    private fun aksiHasil(context: Context) = "${context.packageName}.HASIL_PASANG"

    /** Aplikasi ini installer of record-nya sendiri (Android 12+). */
    private fun bisaTanpaKetukan(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        if (!context.packageManager.canRequestPackageInstalls()) return false
        return try {
            context.packageManager.getInstallSourceInfo(context.packageName)
                .installingPackageName == context.packageName
        } catch (e: Exception) {
            false
        }
    }

    /**
     * @return `"dimulai"`, `"izin"` ("Instal aplikasi tidak dikenal" belum
     *         diizinkan), atau `"gagal: ..."`.
     */
    fun pasang(context: Context, jalur: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()
        ) {
            return "izin"
        }

        val berkas = File(jalur)
        if (!berkas.isFile) return "gagal: berkas tidak ada"

        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(context.packageName)
        params.setSize(berkas.length())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(
                if (bisaTanpaKetukan(context)) PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED
                else PackageInstaller.SessionParams.USER_ACTION_UNSPECIFIED,
            )
        }

        var idSesi = -1
        return try {
            idSesi = installer.createSession(params)
            installer.openSession(idSesi).use { sesi ->
                berkas.inputStream().use { masuk ->
                    sesi.openWrite("sidik-pelanggan.apk", 0, berkas.length()).use { keluar ->
                        masuk.copyTo(keluar)
                        sesi.fsync(keluar)
                    }
                }

                val intent = Intent(context, PenerimaHasilPasang::class.java)
                    .setAction(aksiHasil(context))
                // MUTABLE wajib: sistem mengisi status & intent konfirmasi.
                val bendera = PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
                val pending = PendingIntent.getBroadcast(context, idSesi, intent, bendera)
                sesi.commit(pending.intentSender)
            }
            "dimulai"
        } catch (e: Exception) {
            Log.w(TAG, "Sesi pemasangan gagal", e)
            if (idSesi != -1) {
                try { installer.abandonSession(idSesi) } catch (_: Exception) {}
            }
            "gagal: ${e.message}"
        }
    }

    /** Layar setelan "Instal aplikasi tidak dikenal" untuk aplikasi ini. */
    fun bukaIzinPasang(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            context.startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Jaringan aktif tidak berbayar (Wi-Fi/ethernet) dan tersambung internet. */
    fun jaringanTakBerbayar(context: Context): Boolean =
        try {
            val cm = context.getSystemService(ConnectivityManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val caps = cm.getNetworkCapabilities(cm.activeNetwork)
                caps != null &&
                    caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
            } else {
                @Suppress("DEPRECATION")
                cm.activeNetworkInfo?.isConnected == true && !cm.isActiveNetworkMetered
            }
        } catch (e: Exception) {
            false
        }
}

/**
 * Hasil sesi pemasangan. Kalau Android tetap minta konfirmasi (pemasangan
 * pertama, atau Android 11 ke bawah), layar konfirmasinya dibuka dari sini.
 */
class PenerimaHasilPasang : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @Suppress("DEPRECATION")
                val konfirmasi = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT) ?: return
                konfirmasi.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    context.startActivity(konfirmasi)
                } catch (e: Exception) {
                    // APK tetap tersimpan; ketukan "Pasang" berikutnya mencoba lagi.
                    Log.w("PemasangSesi", "Layar konfirmasi tidak bisa dibuka", e)
                }
            }
            PackageInstaller.STATUS_SUCCESS -> Log.i("PemasangSesi", "Pembaruan terpasang")
            else -> Log.w(
                "PemasangSesi",
                "Pemasangan gagal ($status): ${intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)}",
            )
        }
    }
}
