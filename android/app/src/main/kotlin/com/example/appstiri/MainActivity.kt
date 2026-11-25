package com.example.appstiri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        // Request the fastest mode at the current resolution. Android retains
        // control under battery saver, thermal limits and the user's settings.
        window.decorView.post {
            val display = window.decorView.display ?: return@post
            val current = display.mode
            val fastest = display.supportedModes
                .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
                .maxByOrNull { it.refreshRate } ?: return@post
            window.attributes = window.attributes.apply {
                preferredDisplayModeId = fastest.modeId
                preferredRefreshRate = fastest.refreshRate
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "appstiri/timezone")
            .setMethodCallHandler { call, result ->
                if (call.method == "getTimeZone") {
                    result.success(TimeZone.getDefault().id)
                } else {
                    result.notImplemented()
                }
            }
    }
}
