package com.example.loyallig_flutter

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.example.loyallig_flutter/notification_permissions"
        private const val POST_NOTIFICATIONS_PERMISSION = "android.permission.POST_NOTIFICATIONS"
        private const val REQUEST_CODE_NOTIFICATIONS = 10042
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkStatus" -> result.success(buildPermissionState())
                    "requestPermission" -> handleRequestPermission(result)
                    "openNotificationSettings" -> openAppNotificationSettings(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun buildPermissionState(): Map<String, Any> {
        val areNotificationsEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
        val permissionGranted = if (Build.VERSION.SDK_INT >= 33) {
            ContextCompat.checkSelfPermission(this, POST_NOTIFICATIONS_PERMISSION) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            areNotificationsEnabled
        }
        val shouldShowRationale = if (Build.VERSION.SDK_INT >= 33 && !permissionGranted) {
            ActivityCompat.shouldShowRequestPermissionRationale(this, POST_NOTIFICATIONS_PERMISSION)
        } else {
            false
        }
        return mapOf(
            "granted" to (areNotificationsEnabled && permissionGranted),
            "permissionGranted" to permissionGranted,
            "areNotificationsEnabled" to areNotificationsEnabled,
            "shouldShowRationale" to shouldShowRationale,
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33) {
            result.success(buildPermissionState())
            return
        }

        val currentGranted = ContextCompat.checkSelfPermission(
            this,
            POST_NOTIFICATIONS_PERMISSION,
        ) == PackageManager.PERMISSION_GRANTED

        if (currentGranted) {
            result.success(buildPermissionState())
            return
        }

        if (pendingPermissionResult != null) {
            pendingPermissionResult?.success(buildPermissionState())
            pendingPermissionResult = null
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(POST_NOTIFICATIONS_PERMISSION),
            REQUEST_CODE_NOTIFICATIONS,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_NOTIFICATIONS) {
            val callback = pendingPermissionResult
            pendingPermissionResult = null
            callback?.success(buildPermissionState())
        }
    }

    private fun openAppNotificationSettings(result: MethodChannel.Result) {
        val primaryIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        }
        primaryIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            startActivity(primaryIntent)
            result.success(true)
        } catch (_: Exception) {
            try {
                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallbackIntent)
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
