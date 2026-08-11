package com.cloudcatcher.mars_launcher

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity class that sets up method channels for communication between Flutter and native Android code.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL_OPEN_DEFAULT_LAUNCHER_SETTINGS = "com.cloudcatcher.mars_launcher/open_default_launcher_settings"
    private val CHANNEL_NOTIFY_APP_CHANGES = "com.cloudcatcher.mars_launcher/notify_app_changes"
    private val CHANNEL_INSTALLED_APPS = "com.cloudcatcher.mars_launcher/installed_apps"
    private val CHANNEL_LAUNCH_APP = "com.cloudcatcher.mars_launcher/launch_app"
    private val CHANNEL_OPEN_APP_SETTINGS = "com.cloudcatcher.mars_launcher/open_app_settings"
    private val CHANNEL_STATUS_BAR = "com.cloudcatcher.mars_launcher/status_bar"

    // Fully hidden by default (clean look for all accent colors); Dart syncs
    // this to the persisted setting right after startup via CHANNEL_STATUS_BAR.
    private var statusBarHidden = true

    /**
     * Called when the activity is starting. Sets up method channels for Flutter communication.
     * @param savedInstanceState If the activity is being re-initialized after previously being shut down then this Bundle contains the data it most recently supplied in onSaveInstanceState(Bundle).
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        applyStatusBarVisibility()

        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            // MethodChannel for retrieving installed apps
            MethodChannel(messenger, CHANNEL_INSTALLED_APPS).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        Thread {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }
                    "getAppInfo" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("INVALID_ARGUMENT", "Package name is required", null)
                        } else {
                            Thread {
                                val info = getAppInfo(packageName)
                                runOnUiThread { result.success(info) }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }

            // MethodChannel for launching an app
            MethodChannel(messenger, CHANNEL_LAUNCH_APP).setMethodCallHandler { call, result ->
                if (call.method == "launchApp") {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = launchApp(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

            // MethodChannel for opening the app settings page
            MethodChannel(messenger, CHANNEL_OPEN_APP_SETTINGS).setMethodCallHandler { call, result ->
                if (call.method == "openAppSettings") {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = openAppSettings(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        }

        // MethodChannel for opening the default launcher settings
        MethodChannel(messenger, CHANNEL_OPEN_DEFAULT_LAUNCHER_SETTINGS).setMethodCallHandler { call, result ->
            when (call.method) {
                "openLauncherSettings" -> {
                    openDefaultLauncherSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // MethodChannel for notifying app changes
        MethodChannel(messenger, CHANNEL_NOTIFY_APP_CHANGES).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerAppChangeReceiver" -> {
                    AppChangeReceiver.registerReceiver(this, MethodChannel(messenger, CHANNEL_NOTIFY_APP_CHANGES))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // MethodChannel for switching between fully hiding the status bar and
        // just letting Flutter color-blend it (see SettingsManager in Dart)
        MethodChannel(messenger, CHANNEL_STATUS_BAR).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHidden" -> {
                    statusBarHidden = call.arguments as? Boolean ?: true
                    applyStatusBarVisibility()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Re-applies the current status bar visibility whenever the window
     * regains focus (e.g. returning from Recents), so a hidden bar never
     * stays revealed after a resume.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            applyStatusBarVisibility()
        }
    }

    /**
     * Hides or shows the status bar only (nav bar untouched), no
     * immersive/fullscreen mode. While hidden, swiping from the top reveals
     * it transiently (system takes the first swipe, a second one is needed
     * to actually pull the notification shade down).
     *
     * Edge-to-edge (decorFitsSystemWindows = false) stays on regardless of
     * mode -- that's what lets Flutter draw its own background color behind
     * the status bar for the blend mode. Toggling it off here would break
     * that rendering and the app's own inset handling.
     */
    private fun applyStatusBarVisibility() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        if (statusBarHidden) {
            controller.hide(WindowInsetsCompat.Type.statusBars())
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        } else {
            controller.show(WindowInsetsCompat.Type.statusBars())
        }
    }

    /**
     * Opens the default launcher settings.
     */
    private fun openDefaultLauncherSettings() {
        startActivity(Intent(android.provider.Settings.ACTION_HOME_SETTINGS))
    }

    /**
     * Retrieves a list of installed apps that have a launcher entry. Uses
     * queryIntentActivities with ACTION_MAIN/CATEGORY_LAUNCHER, which is far
     * cheaper than iterating every installed package.
     */
    private fun getInstalledApps(): List<Map<String, String>> {
        val pm: PackageManager = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val appList = mutableListOf<Map<String, String>>()
        val seen = HashSet<String>()

        for (resolveInfo in resolveInfos) {
            val packageName = resolveInfo.activityInfo?.packageName ?: continue
            if (packageName == "com.cloudcatcher.mars_launcher") continue
            if (!seen.add(packageName)) continue
            appList.add(resolveInfoToMap(resolveInfo, packageName, pm))
        }

        return appList
    }

    /**
     * Retrieves info for a single app by package name. Returns null if the
     * package has no launcher entry (e.g. uninstalled or not launchable).
     */
    private fun getAppInfo(packageName: String): Map<String, String>? {
        if (packageName == "com.cloudcatcher.mars_launcher") return null
        val pm: PackageManager = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
            setPackage(packageName)
        }
        val resolveInfo = pm.queryIntentActivities(mainIntent, 0).firstOrNull() ?: return null
        return resolveInfoToMap(resolveInfo, packageName, pm)
    }

    private fun resolveInfoToMap(
        resolveInfo: ResolveInfo,
        packageName: String,
        pm: PackageManager
    ): Map<String, String> {
        val appInfo = resolveInfo.activityInfo?.applicationInfo
        val appName = appInfo?.loadLabel(pm)?.toString()
            ?: resolveInfo.loadLabel(pm).toString()
        val isSystemApp = ((appInfo?.flags ?: 0) and ApplicationInfo.FLAG_SYSTEM) != 0
        return mapOf(
            "packageName" to packageName,
            "appName" to appName,
            "isSystemApp" to isSystemApp.toString()
        )
    }

    /**
     * Launches an app given its package name.
     * @param packageName The package name of the app.
     * @return true if the app was successfully launched, false otherwise.
     */
    private fun launchApp(packageName: String): Boolean {
        return try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                startActivity(launchIntent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Opens the settings page for a specific app given its package name.
     * @param packageName The package name of the app.
     * @return true if the settings page was successfully opened, false otherwise.
     */
    private fun openAppSettings(packageName: String): Boolean {
        return try {
            val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = android.net.Uri.parse("package:$packageName")
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}