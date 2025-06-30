package com.example.well_being

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import android.util.Base64
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar


class MainActivity : FlutterActivity() {

    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var myPackageManager: PackageManager
    private val CHANNEL = "com.flutter.well_being/stats"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        myPackageManager = context.packageManager
    }


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler {
                call, result ->
                if(checkUsageStatsPermission()){
                    if (call.method == "getUsageStats"){
                        result.success(fetchUsageStats())
                    } else {
                        result.notImplemented()
                    }
                } else {
                    Intent( Settings.ACTION_USAGE_ACCESS_SETTINGS ).apply {
                        startActivity( this )
                    }
                }

        }
    }

    private fun checkUsageStatsPermission() : Boolean {
        val appOpsManager = getSystemService(AppCompatActivity.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.checkOpNoThrow(
                "android:get_usage_stats",
                Process.myUid(), packageName
            )
        }
        else {
            appOpsManager.checkOpNoThrow(
                "android:get_usage_stats",
                Process.myUid(), packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }


    private fun getInstalledAppList(): List<String> {
        val apps = myPackageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        return apps
            .map { it.packageName }
    }

    private fun getAppLogoBase64(packageName: String): String? {
        try {
            val logo = myPackageManager.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(logo.intrinsicWidth, logo.intrinsicHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            logo.setBounds(0, 0, canvas.width, canvas.height)
            logo.draw(canvas)
            val byteArrayOutputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()
            return Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception){
            return null
        }
    }

    private fun getStartTime(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        return calendar.timeInMillis
    }
    private fun fetchDailyUsageStats(startTime: Long, endTime: Long) : List<Map<String, Any?>> {
        val usageStats = usageStatsManager
            .queryUsageStats( UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val installedAppList = getInstalledAppList().toSet()
        val requiredStats: List<UsageStats> = usageStats
            .filter { installedAppList.contains(it.packageName) && it.totalTimeInForeground > 0  }
            .sortedByDescending { it.totalTimeInForeground }
        return requiredStats.map {
            mapOf(
                "packageName" to it.packageName,
                "totalTimeInForeground" to it.totalTimeInForeground,
                "lastTimeUsed" to it.lastTimeUsed,
                "packageLogo" to getAppLogoBase64(it.packageName)
            )
        }
    }
}