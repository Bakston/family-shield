package com.familyshield.family_shield

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class FamilyAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Toast.makeText(this, "Служба доступности Family Shield активна", Toast.LENGTH_SHORT).show()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Здесь в будущем мы будем отслеживать запуск приложений и блокировки
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            // Например, можем проверять пакеты запущенных приложений
        }
    }

    override fun onInterrupt() {
        // Сервис был прерван системой
    }
}