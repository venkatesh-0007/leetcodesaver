package com.leetstreak.leetstreak

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class StreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val streak = prefs.getLong("flutter.current_streak", 0L).toInt()
            val isSolvedToday = prefs.getBoolean("flutter.today_solved", false)

            val views = RemoteViews(context.packageName, R.layout.streak_widget_layout)

            // Update streak text
            views.setTextViewText(R.id.widget_streak_number, streak.toString())

            // Update status text and color
            if (isSolvedToday) {
                views.setTextViewText(R.id.widget_status_text, "✓ Secured")
                views.setTextColor(R.id.widget_status_text, Color.parseColor("#22C55E"))
                views.setTextViewText(R.id.widget_btn_save_streak, "✓ Streak Saved Today")
            } else {
                views.setTextViewText(R.id.widget_status_text, "⚠ At Risk")
                views.setTextColor(R.id.widget_status_text, Color.parseColor("#EF4444"))
                views.setTextViewText(R.id.widget_btn_save_streak, "⚡ Save Streak")
            }

            // Intent to open App Dashboard
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingLaunch = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingLaunch)

            // Intent to directly open Streak Saver Flow
            val saveIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("open_streak_saver", true)
            }
            val pendingSave = PendingIntent.getActivity(
                context,
                1,
                saveIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_save_streak, pendingSave)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, StreakWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}

