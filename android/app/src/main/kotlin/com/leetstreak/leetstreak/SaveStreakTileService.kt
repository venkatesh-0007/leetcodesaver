package com.leetstreak.leetstreak

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class SaveStreakTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val streak = prefs.getLong("flutter.current_streak", 0L).toInt()
        val isSolvedToday = prefs.getBoolean("flutter.today_solved", false)

        tile.label = "Save Streak"
        tile.icon = Icon.createWithResource(this, R.drawable.ic_stat_streak)

        if (isSolvedToday) {
            tile.state = Tile.STATE_ACTIVE
            tile.subtitle = "$streak days (Saved)"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.subtitle = if (streak > 0) "$streak days (At Risk)" else "Save Streak"
        }

        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_streak_saver", true)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // Android 14+ (API 34)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

