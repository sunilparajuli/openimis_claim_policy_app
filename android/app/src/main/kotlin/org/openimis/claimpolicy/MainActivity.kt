package org.openimis.claimpolicy

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings

class MainActivity: FlutterFragmentActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingKind: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.openimis/permissions")
            .setMethodCallHandler { call, result ->
                val kind = call.argument<String>("permission")
                when (call.method) {
                    "status" -> result.success(status(kind))
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(true)
                    }
                    "request" -> {
                        val permissions = permissions(kind)
                        if (permissions.isEmpty()) {
                            result.error("INVALID_PERMISSION", "Unknown permission", null)
                        } else if (pendingResult != null) {
                            result.error("BUSY", "A permission request is already open", null)
                        } else if (status(kind) == "granted") {
                            result.success("granted")
                        } else {
                            pendingKind = kind
                            pendingResult = result
                            requestPermissions(permissions, 704)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun permissions(kind: String?): Array<String> = when (kind) {
        "camera" -> arrayOf(Manifest.permission.CAMERA)
        "location" -> arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
        "photos" -> if (Build.VERSION.SDK_INT >= 34) arrayOf("android.permission.READ_MEDIA_IMAGES", "android.permission.READ_MEDIA_VISUAL_USER_SELECTED")
            else if (Build.VERSION.SDK_INT >= 33) arrayOf("android.permission.READ_MEDIA_IMAGES")
            else arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        else -> emptyArray()
    }

    private fun granted(permission: String) = checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun status(kind: String?): String {
        if (kind == "location" && granted(Manifest.permission.ACCESS_COARSE_LOCATION)) return "granted"
        val required = permissions(kind)
        if (required.isEmpty()) return "unavailable"
        if (granted(required.first())) return "granted"
        if (kind == "photos" && Build.VERSION.SDK_INT >= 34 && granted("android.permission.READ_MEDIA_VISUAL_USER_SELECTED")) return "limited"
        return "denied"
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 704) {
            pendingResult?.success(status(pendingKind))
            pendingResult = null
            pendingKind = null
        }
    }
}
