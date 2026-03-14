# nanosecond-widget

Widget Android que ejecuta el binario Crystal compilado y muestra su output en pantalla de inicio.

## Setup

### 1. Copiar el binario Crystal al proyecto

```bash
cp android/libs/arm64-v8a/nanosecond nanosecond-widget/app/src/main/assets/nanosecond
```

### 2. Compilar e instalar

```bash
cd nanosecond-widget
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

### 3. Agregar el widget

Mantén presionado en la pantalla de inicio → Widgets → **Nanosecond**

## Cómo funciona

```
Crystal binary (nanosecond)
    → stdout línea por línea (~7ms/tick)
    → NanosecondService (ForegroundService) lee BufferedReader
    → SharedPreferences (last_time)
    → broadcast ACTION_TICK
    → NanosecondWidget.onReceive()
    → RemoteViews.setTextViewText()
    → pantalla de inicio
```

El binario Crystal ya detecta ANDROID_ROOT y usa `puts` en vez de `\r`.
