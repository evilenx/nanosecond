# nanosecond

144Hz clock. Millisecond precision.

    14-03-2026 01:20:17.231

## build

    crystal build src/nanosecond.cr -o bin/nanosecond --release

## android

    export ANDROID_NDK_HOME=/path/to/ndk-r25c
    ./scripts/build-android.sh
    cd nanosecond-widget && ./gradlew assembleDebug

APK: https://github.com/evilenx/nanosecond/releases/tag/v1.1.0

## bugs

- widget needs a tap to start after install/reboot
- service restarts every ~36s (Bionic fiber stack overflow)
