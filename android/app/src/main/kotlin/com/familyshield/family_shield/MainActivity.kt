package com.familyshield.family_shield

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.family_shield/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestDeviceAdmin") {
                val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                val compName = ComponentName(this, DeviceAdminReceiver::class.java)

                if (!devicePolicyManager.isAdminActive(compName)) {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Необходимо для защиты приложения от удаления ребёнком.")
                    }
                    startActivityForResult(intent, 1001)
                    result.success(false)
                } else {
                    result.success(true)
                }
            } else if (call.method == "requestAccessibility") {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                startActivity(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}