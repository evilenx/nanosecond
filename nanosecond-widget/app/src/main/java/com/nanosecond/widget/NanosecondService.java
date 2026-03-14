package com.nanosecond.widget;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.IBinder;
import android.util.Log;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class NanosecondService extends Service {

    static final String TAG = "NanosecondService";
    static final String PREFS = "nanosecond";
    static final String KEY_TIME = "last_time";
    static final String ACTION_TICK = "com.nanosecond.widget.TICK";
    static final String CHANNEL_ID = "nanosecond_channel";

    private Process crystalProcess;
    private Thread readerThread;
    private volatile boolean running = false;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(1, buildNotification());
        startCrystalBinary();
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        running = false;
        if (crystalProcess != null) crystalProcess.destroy();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    private void startCrystalBinary() {
        try {
            String binPath = getApplicationInfo().nativeLibraryDir + "/libnanosecond.so";
            Log.i(TAG, "Ejecutando: " + binPath);

            ProcessBuilder pb = new ProcessBuilder(binPath);
            pb.environment().put("ANDROID_ROOT", "/system");
            pb.redirectErrorStream(true);
            crystalProcess = pb.start();

            running = true;
            readerThread = new Thread(() -> {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(crystalProcess.getInputStream()))) {
                    String line;
                    SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
                    long lastBroadcast = 0;
                    while (running && (line = reader.readLine()) != null) {
                        final String tick = line.trim();
                        if (tick.isEmpty()) continue;
                        prefs.edit().putString(KEY_TIME, tick).apply();
                        long now = System.currentTimeMillis();
                        if (now - lastBroadcast < 50) continue;
                        lastBroadcast = now;
                        sendBroadcast(new Intent(ACTION_TICK)
                            .setPackage(getPackageName()));
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Error leyendo stdout", e);
                }
                int exit = crystalProcess.exitValue(); Log.w(TAG, "Crystal process ended -- exit code: " + exit + " (0x" + Integer.toHexString(exit) + ") -- reiniciando...");
                if (running) {
                    try { Thread.sleep(500); } catch (InterruptedException ignored) {}
                    startCrystalBinary();
                }
            }, "crystal-reader");
            readerThread.start();

        } catch (Exception e) {
            Log.e(TAG, "No se pudo iniciar el binario Crystal", e);
        }
    }

    private Notification buildNotification() {
        NotificationManager nm = getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel(
            CHANNEL_ID, "Nanosecond", NotificationManager.IMPORTANCE_MIN));
        return new Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Nanosecond")
            .setContentText("Corriendo en background")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build();
    }
}
