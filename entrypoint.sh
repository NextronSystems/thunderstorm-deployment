#!/bin/sh

# update THOR signatures
"$TARGET_DIR/thor-util" update

# run Thunderstorm service
exec "$TARGET_DIR/tools/thunderstorm" \
    "--host" "${HOST:-0.0.0.0}" \
    "--port" "${PORT:-8000}" \
    "--cert" "$TLS_CERT" \
    "--key" "$TLS_KEY" \
    "--queue-storage" "${QUEUE_STORAGE:-$TEMP_DIR/.persisted-uploads}" \
    "--queue-warn-size" "${QUEUE_WARN_SIZE:-50000}" \
    "--result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
    "--store-samples-score" "${STORE_SAMPLES_SCORE:-200}" \
    "--thor-binary" "${THOR_BINARY:-$TARGET_DIR/thor-linux-64}" \
    "--upload-dir" "$UPLOAD_DIR" \
    "--vfs-dir" "$VFS_DIR"