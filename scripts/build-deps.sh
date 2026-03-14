#!/bin/bash
set -e

TARGET="aarch64-linux-android24"
API_LEVEL=24
NDK="${ANDROID_NDK_HOME:?ERROR: Set ANDROID_NDK_HOME}"
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64"
SYSROOT="$TOOLCHAIN/sysroot"

export CC="$TOOLCHAIN/bin/aarch64-linux-android$API_LEVEL-clang"
export CXX="$TOOLCHAIN/bin/aarch64-linux-android$API_LEVEL-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"

BUILD_DIR="android/build"
INSTALL_DIR="$PWD/android/libs/arm64-v8a/deps"

mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

echo "=== Compilando libgc ==="
cd "$BUILD_DIR"

if [ ! -d "gc-8.2.6" ]; then
    curl -L https://github.com/ivmai/bdwgc/releases/download/v8.2.6/gc-8.2.6.tar.gz | tar xz
fi

cd gc-8.2.6

./configure \
    --host=aarch64-linux-android \
    --prefix="$INSTALL_DIR" \
    --enable-static \
    --disable-shared \
    --disable-threads \
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="-fPIC -DANDROID -DNO_GETCONTEXT"

make clean 2>/dev/null || true
make -j$(sysctl -n hw.ncpu)
make install

echo "=== libgc lista ==="
ls -la "$INSTALL_DIR/lib/"
