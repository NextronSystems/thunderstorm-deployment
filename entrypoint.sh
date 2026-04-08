#!/bin/sh

# update THOR signatures
"$TARGET_DIR/thor-util" update

# build optional TLS and VFS arguments
EXTRA_ARGS=""
[ -n "$TLS_CERT" ] && EXTRA_ARGS="$EXTRA_ARGS --cert $TLS_CERT"
[ -n "$TLS_KEY" ]  && EXTRA_ARGS="$EXTRA_ARGS --key $TLS_KEY"
[ -n "$VFS_DIR" ]  && EXTRA_ARGS="$EXTRA_ARGS --vfs-dir $VFS_DIR"

# run Thunderstorm service
exec "$TARGET_DIR/tools/thunderstorm" \
    "--host" "${HOST:-0.0.0.0}" \
    "--port" "${PORT:-8000}" \
    "--queue-storage" "${QUEUE_STORAGE:-$TEMP_DIR/.persisted-uploads}" \
    "--queue-warn-size" "${QUEUE_WARN_SIZE:-50000}" \
    "--result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
    "--store-samples-score" "${STORE_SAMPLES_SCORE:-200}" \
    "--thor-location" "${THOR_LOCATION:-$TARGET_DIR}" \
    "--upload-dir" "$UPLOAD_DIR" \
    "--signature-update-interval" "$SIGNATURE_UPDATE_INTERVAL" \
    $EXTRA_ARGS \
    "--" \
    "--no-json" \
    "--template" "$TARGET_DIR/config/custom-thor.yml"