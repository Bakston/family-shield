package com.familyshield.family_shield

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.family_shield/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    try {
                        val stats = getAppUsageStats()
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Failed to get usage stats: ${e.message}", null)
                    }
                }
                "checkUsagePermission" -> {
                    try {
                        val granted = checkUsageStatsPermission()
                        result.success(granted)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Failed to check usage permission: ${e.message}", null)
                    }
                }
                "requestUsagePermission" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Failed to request usage permission: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getAppUsageStats(): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        // Считаем интервал с начала сегодняшнего дня (00:00) до текущего момента
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        // Запрашиваем статистику у системы Android
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val usageMap = mutableMapOf<String, Long>()
        if (stats != null) {
            for (stat in stats) {
                // Накапливаем время активного использования на переднем плане (в миллисекундах)
                if (stat.totalTimeInForeground > 0) {
                    val existingTime = usageMap[stat.packageName] ?: 0L
                    usageMap[stat.packageName] = existingTime + stat.totalTimeInForeground
                }
            }
        }
        return usageMap
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}