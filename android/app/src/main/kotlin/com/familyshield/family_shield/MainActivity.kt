package com.familyshield.family_shield

import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val USAGE_CHANNEL = "com.example.family_shield/usage_stats"
    private val ADMIN_CHANNEL = "com.example.family_shield/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    try {
                        result.success(getAppUsageStats())
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                }

                "checkUsagePermission" -> result.success(checkUsageStatsPermission())
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADMIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkDeviceAdmin" -> result.success(isDeviceAdminActive())
                "requestDeviceAdmin" -> {
                    val compName = ComponentName(this, DeviceAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Защита Family Shield от удаления ребёнком")
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "checkAccessibility" -> result.success(isAccessibilityServiceEnabled())
                "requestAccessibility" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "checkDefaultLauncher" -> result.success(isDefaultLauncher())
                "requestDefaultLauncher" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        val intent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                }

                "setBlockedPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val prefs = getSharedPreferences("family_shield_native", Context.MODE_PRIVATE)
                    prefs.edit().putStringSet("blocked_packages", packages.toSet()).apply()
                    result.success(true)
                }

                "setParentBypass" -> {
                    val minutes = call.argument<Int>("minutes") ?: 0
                    val prefs = getSharedPreferences("family_shield_native", Context.MODE_PRIVATE)
                    val bypassUntil = if (minutes > 0) {
                        System.currentTimeMillis() + minutes * 60_000L
                    } else {
                        0L
                    }
                    prefs.edit().putLong("parent_bypass_until", bypassUntil).apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    private fun isDeviceAdminActive(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val compName = ComponentName(this, DeviceAdminReceiver::class.java)
        return dpm.isAdminActive(compName)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = ComponentName(this, FamilyAccessibilityService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponent) {
                return true
            }
        }
        return false
    }

    private fun getAppUsageStats(): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, calendar.timeInMillis, System.currentTimeMillis()
        )
        val usageMap = mutableMapOf<String, Long>()
        if (stats != null) {
            for (stat in stats) {
                if (stat.totalTimeInForeground > 0) {
                    usageMap[stat.packageName] = (usageMap[stat.packageName] ?: 0L) + stat.totalTimeInForeground
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