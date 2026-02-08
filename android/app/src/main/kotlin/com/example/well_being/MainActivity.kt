package com.example.well_being

import android.app.AppOpsManager
import android.app.usage.UsageEvents
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
import androidx.core.graphics.createBitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale


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
                    when (call.method) {
                        "getDailyUsageStats" -> {
                            val date = call.argument<String>("date") ?: ""
                            val stats = fetchDailyUsageStats(date)
                            result.success(stats)
                        }
                        "getWeeklyUsageStats" -> {
                            result.success(fetchWeeklyUsageStats())
                        }
                        else -> {
                            result.notImplemented()
                        }
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
        return try {
            val logo = myPackageManager.getApplicationIcon(packageName)
            val width = if (logo.intrinsicWidth > 0) logo.intrinsicWidth else 96
            val height = if (logo.intrinsicHeight > 0) logo.intrinsicHeight else 96
            val bitmap = createBitmap(width, height)
            val canvas = Canvas(bitmap)
            logo.setBounds(0, 0, canvas.width, canvas.height)
            logo.draw(canvas)
            val byteArrayOutputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun getStartTime(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        return calendar.timeInMillis
    }
//    private fun fetchDailyUsageStats(startTime: Long, endTime: Long) : List<Map<String, Any?>> {
//        val usageStats = usageStatsManager
//            .queryUsageStats( UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
//        val installedAppList = getInstalledAppList().toSet()
//        val requiredStats: List<UsageStats> = usageStats
//            .filter { installedAppList.contains(it.packageName) && it.totalTimeInForeground > 0  }
//            .sortedByDescending { it.totalTimeInForeground }
//        return requiredStats.map {
//            mapOf(
//                "packageName" to it.packageName,
//                "totalTimeInForeground" to it.totalTimeInForeground,
//                "lastTimeUsed" to it.lastTimeUsed,
//                "packageLogo" to getAppLogoBase64(it.packageName)
//            )
//        }
//    }

    private fun fetchWeeklyUsageStats(): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        val calendar = Calendar.getInstance()

        for( i in 0 until 7){
            calendar.timeInMillis = System.currentTimeMillis()
            calendar.add(Calendar.DAY_OF_YEAR, -i)

            val endOfDay = calendar.timeInMillis

            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)

            val startOfDay = calendar.timeInMillis

            val usageEvents = usageStatsManager.queryEvents(startOfDay, endOfDay)
            val event = UsageEvents.Event()

            var lastForegroundTime: Long? = null
            var lastPackage: String? = null
            val appScreenTime = mutableMapOf<String, Long>()

            while (usageEvents.hasNextEvent()){
                usageEvents.getNextEvent(event)

                when(event.eventType){
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        lastForegroundTime = event.timeStamp
                        lastPackage = event.packageName
                    }

                    UsageEvents.Event.ACTIVITY_PAUSED -> {
                        if (lastForegroundTime != null && lastPackage == event.packageName){
                            val duration = event.timeStamp - lastForegroundTime
                            if (appScreenTime.containsKey(lastPackage)) {
                                appScreenTime[lastPackage!!] = appScreenTime[lastPackage]!! + duration
                            } else {
                                appScreenTime[lastPackage!!] = duration
                            }
                            lastForegroundTime = null
                            lastPackage = null
                        }
                    }
                }
            }

            val totalDuration = appScreenTime.values.sum()

            val formattedDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date(startOfDay))
            result.add(mapOf("date" to formattedDate, "duration" to totalDuration))

        }

        return result.reversed()
    }

    private fun getActualApplicationName(packageName: String): String {
        try{
            val applicationInfo = myPackageManager.getApplicationInfo(packageName, 0)
            return myPackageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException){
            return packageName
        }

    }
    private fun fetchDailyUsageStats(date: String): List<Map<String, Any?>> {
        val formatter = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
        val calendar = Calendar.getInstance()

        // Parse the input date
        val parsedDate = formatter.parse(date) ?: return emptyList()

        // Set start time to 00:00:00 of the given date
        calendar.time = parsedDate
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // Set end time to 23:59:59.999 of the same date
        calendar.set(Calendar.HOUR_OF_DAY, 23)
        calendar.set(Calendar.MINUTE, 59)
        calendar.set(Calendar.SECOND, 59)
        calendar.set(Calendar.MILLISECOND, 999)
        val endTime = calendar.timeInMillis

        // Proceed with querying usage events
        val event = UsageEvents.Event()
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)

        var lastForegroundTime: Long? = null
        var lastPackage: String? = null
        val appScreenTime = mutableMapOf<String, Long>()

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    lastForegroundTime = event.timeStamp
                    lastPackage = event.packageName
                }

                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    if (lastForegroundTime != null && lastPackage == event.packageName) {
                        val duration = event.timeStamp - lastForegroundTime
                        if (appScreenTime.containsKey(lastPackage)) {
                            appScreenTime[lastPackage!!] = appScreenTime[lastPackage]!! + duration
                        } else {
                            appScreenTime[lastPackage!!] = duration
                        }
                        lastForegroundTime = null
                        lastPackage = null
                    }
                }
            }
        }

        return appScreenTime
            .filter { it.value > 0 }
            .toList()
            .sortedByDescending { it.second }
            .map { (packageName, duration) ->
                mapOf<String, Any?>(
                    "packageName" to getActualApplicationName(packageName),
                    "duration" to duration,
                    "packageLogo" to getAppLogoBase64(packageName),
                )
            }
    }

}