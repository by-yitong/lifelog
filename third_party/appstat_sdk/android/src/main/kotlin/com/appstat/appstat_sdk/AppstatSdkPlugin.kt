package com.appstat.appstat_sdk

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class AppstatSdkPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null
    private var previousHandler: Thread.UncaughtExceptionHandler? = null

    private val crashForwarder = object : Thread.UncaughtExceptionHandler {
        override fun uncaughtException(thread: Thread, throwable: Throwable) {
            forwardCrash(throwable)
            previousHandler?.uncaughtException(thread, throwable)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(crashForwarder)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (Thread.getDefaultUncaughtExceptionHandler() === crashForwarder) {
            Thread.setDefaultUncaughtExceptionHandler(previousHandler)
        }
        previousHandler = null
        channel = null
    }

    private fun forwardCrash(throwable: Throwable) {
        val target = channel ?: return
        val payload = mapOf(
            "type" to "android-java",
            "exception" to throwable.toString(),
            "stack" to Log.getStackTraceString(throwable),
        )
        try {
            if (Looper.myLooper() == Looper.getMainLooper()) {
                target.invokeMethod(METHOD_NATIVE_CRASH, payload)
            } else {
                Handler(Looper.getMainLooper()).post {
                    try {
                        target.invokeMethod(METHOD_NATIVE_CRASH, payload)
                    } catch (_: Throwable) {
                    }
                }
            }
        } catch (_: Throwable) {
        }
    }

    private companion object {
        const val CHANNEL_NAME = "appstat_sdk"
        const val METHOD_NATIVE_CRASH = "nativeCrash"
    }
}
