#!/bin/bash
set -e

# build-android.sh — Crystal → ARM64 Android
# Fix TLS: parchea PT_TLS p_align en el program header (lo que Bionic realmente lee)

TARGET="aarch64-linux-android24"
API_LEVEL=24
NDK="${ANDROID_NDK_HOME:?ERROR: Set ANDROID_NDK_HOME}"
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64"
SYSROOT="$TOOLCHAIN/sysroot"
DEPS_DIR="$PWD/android/deps"
OUTPUT_DIR="$PWD/android/libs/arm64-v8a"
BINARY="$OUTPUT_DIR/nanosecond"
OBJ_FILE="$OUTPUT_DIR/nanosecond.o"
LLVM_READELF="$TOOLCHAIN/bin/llvm-readelf"

# fix_tls_align.py debe estar junto a este script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIX_SCRIPT="$SCRIPT_DIR/fix_tls_align.py"

mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------
# 1. Crystal compila + linkea automáticamente
# ---------------------------------------------------------------
echo "=== Compilando con Crystal ==="
crystal build src/nanosecond.cr \
    --cross-compile \
    --target "$TARGET" \
    -o "$BINARY" \
    --release \
    --emit obj

if [ ! -f "$BINARY" ] || file "$BINARY" | grep -q "relocatable"; then
    echo "Crystal solo generó .o — linkeando manualmente..."
    [ ! -f "$OBJ_FILE" ] && OBJ_FILE=$(find "$OUTPUT_DIR" -name "*.o" | head -1)

    "$TOOLCHAIN/bin/aarch64-linux-android24-clang" \
        -target "$TARGET" \
        -static \
        -Wl,--no-rosegment \
        -Wl,-z,max-page-size=4096 \
    -Wl,-z,stacksize=8388608 \
        "$OBJ_FILE" \
        -o "$BINARY" \
        -L"$DEPS_DIR/lib" \
        -L"$SYSROOT/usr/lib/aarch64-linux-android/$API_LEVEL" \
        -lgc -levent -levent_pthreads -ldl -lm -lc
else
    echo "Crystal linkeó automáticamente → $BINARY"
fi

# ---------------------------------------------------------------
# 2. Verificar PT_TLS antes del parche
# ---------------------------------------------------------------
echo "=== PT_TLS antes del parche ==="
"$LLVM_READELF" -l "$BINARY" | grep -A1 "TLS" || echo "(sin PT_TLS visible)"

# ---------------------------------------------------------------
# 3. Parchear p_align del program header PT_TLS con Python
#    (llvm-objcopy solo toca section headers, Bionic lee program headers)
# ---------------------------------------------------------------
echo "=== Parcheando PT_TLS program header ==="
if [ ! -f "$FIX_SCRIPT" ]; then
    echo "ERROR: no se encontró $FIX_SCRIPT"
    echo "Copia fix_tls_align.py al directorio scripts/"
    exit 1
fi
python3 "$FIX_SCRIPT" "$BINARY"

# ---------------------------------------------------------------
# 4. Verificación final
# ---------------------------------------------------------------
echo "=== PT_TLS después del parche ==="
"$LLVM_READELF" -l "$BINARY" | grep -A1 "TLS"

echo "=== Binario ==="
file "$BINARY"
ls -la "$BINARY"

echo ""
echo "=== Deploy ==="
echo "  adb push $BINARY /data/local/tmp/"
echo "  adb shell chmod +x /data/local/tmp/nanosecond"
echo "  adb shell /data/local/tmp/nanosecond"
