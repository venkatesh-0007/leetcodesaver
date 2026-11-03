package com.leetstreak.leetstreak

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.quicksettings.TileService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.leetstreak.app/native"
    private var methodChannel: MethodChannel? = null
    private var shouldOpenStreakSaverOnReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("open_streak_saver", false) == true) {
            if (methodChannel != null) {
                methodChannel?.invokeMethod("launchStreakSaver", null)
            } else {
                shouldOpenStreakSaverOnReady = true
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        val streak = call.argument<Int>("streak") ?: 0
                        val isSolvedToday = call.argument<Boolean>("isSolvedToday") ?: false
                        val totalActiveDays = call.argument<Int>("totalActiveDays") ?: 0

                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putLong("flutter.current_streak", streak.toLong())
                            .putBoolean("flutter.today_solved", isSolvedToday)
                            .putLong("flutter.total_active_days", totalActiveDays.toLong())
                            .apply()

                        // Trigger native home screen widget refresh
                        StreakWidgetProvider.updateAllWidgets(applicationContext)

                        // Trigger quick settings tile state refresh
                        try {
                            TileService.requestListeningState(
                                applicationContext,
                                ComponentName(applicationContext, SaveStreakTileService::class.java)
                            )
                        } catch (_: Exception) {}

                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        if (shouldOpenStreakSaverOnReady) {
            shouldOpenStreakSaverOnReady = false
            methodChannel?.invokeMethod("launchStreakSaver", null)
        }
    }
}
