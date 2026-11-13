package com.familyshield.family_shield

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class DeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Отключение администратора запрещено настройками родительского контроля Family Shield."
    }
}