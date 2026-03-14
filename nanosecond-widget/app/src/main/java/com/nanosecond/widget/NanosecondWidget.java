package com.nanosecond.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class NanosecondWidget extends AppWidgetProvider {

    @Override
    public void onUpdate(Context ctx, AppWidgetManager mgr, int[] ids) {
        for (int id : ids) updateViews(ctx, mgr, id);
    }

    @Override
    public void onReceive(Context ctx, Intent intent) {
        super.onReceive(ctx, intent);
        if (NanosecondService.ACTION_TICK.equals(intent.getAction())) {
            AppWidgetManager mgr = AppWidgetManager.getInstance(ctx);
            int[] ids = mgr.getAppWidgetIds(
                new ComponentName(ctx, NanosecondWidget.class));
            for (int id : ids) updateViews(ctx, mgr, id);
        }
    }

    @Override
    public void onDisabled(Context ctx) {
        ctx.stopService(new Intent(ctx, NanosecondService.class));
    }

    private void updateViews(Context ctx, AppWidgetManager mgr, int widgetId) {
        SharedPreferences prefs = ctx.getSharedPreferences(
            NanosecondService.PREFS, Context.MODE_PRIVATE);
        String time = prefs.getString(NanosecondService.KEY_TIME, "--:--:--.---");

        RemoteViews views = new RemoteViews(ctx.getPackageName(), R.layout.widget_layout);
        views.setTextViewText(R.id.tv_time, time);

        // Tap en el widget abre StartActivity, que arranca el servicio desde foreground
        Intent launch = new Intent(ctx, StartActivity.class);
        launch.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent pi = PendingIntent.getActivity(ctx, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_root, pi);

        mgr.updateAppWidget(widgetId, views);
    }
}
