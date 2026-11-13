package com.familyshield.family_shield

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class FamilyAccessibilityService : AccessibilityService() {

    private val defaultRestricted = setOf(
        "com.android.settings",
        "com.android.vending",
        "com.google.android.packageinstaller",
        "com.android.packageinstaller",
        "com.miui.securitycenter",
        "com.coloros.safecenter",
        "com.huawei.systemmanager"
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        val cls = event.className?.toString() ?: ""

        if (pkg == packageName || pkg == "com.android.systemui") return

        val prefs = getSharedPreferences("family_shield_native", Context.MODE_PRIVATE)
        val bypassUntil = prefs.getLong("parent_bypass_until", 0L)
        val isParentBypassActive = System.currentTimeMillis() < bypassUntil

        // Если активен временный доступ родителя (5 минут), разрешаем вход в настройки и приложения
        if (isParentBypassActive) return

        val dynamicBlocked = prefs.getStringSet("blocked_packages", emptySet()) ?: emptySet()

        if (defaultRestricted.contains(pkg) || dynamicBlocked.contains(pkg) ||
            (pkg == "com.android.settings" && cls.contains("DeviceAdminAdd", ignoreCase = true))) {
            performGlobalAction(GLOBAL_ACTION_HOME)
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            if (launchIntent != null) {
                startActivity(launchIntent)
            }
        }
    }

    override fun onInterrupt() {}
}