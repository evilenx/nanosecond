# Nanosecond Clock

Precision time display at 144Hz (6.94ms intervals).

## Features
- Sub-millisecond precision (`%3N`)
- 144Hz refresh rate
- Single file Crystal implementation
- Zero dependencies (std only)
- Cross-platform (Linux, macOS, future: Android-widget)

## Build
```bash
shards build --release
```
## Run
```bash
./bin/nanosecond
```
