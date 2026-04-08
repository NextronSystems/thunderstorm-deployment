#!/bin/sh

# download Thor if not already present
if [ ! -f "$TARGET_DIR/thor-util" ]; then
    if [ -z "$CONTRACT_TOKEN" ]; then
        echo "CONTRACT_TOKEN is required to download Thor!" >&2
        exit 1
    fi
    wget -O "$TEMP_DIR/thor.zip" "https://portal.nextron-systems.com/api/voucher/download/$CONTRACT_TOKEN/thor/linux" && \
        unzip -o -q "$TEMP_DIR/thor.zip" -d "$TARGET_DIR" && \
        rm "$TEMP_DIR/thor.zip"
    "$TARGET_DIR/thor-util" upgrade --techpreview --dev  #TODO: remove once THOR11 is published
fi

# append optional TLS and VFS arguments to THUNDERSTORM_ARGS
[ -n "$TLS_CERT" ] && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --cert $TLS_CERT"
[ -n "$TLS_KEY" ]  && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --key $TLS_KEY"
[ -n "$VFS_DIR" ]  && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --vfs-dir $VFS_DIR"

# run Thunderstorm service
# use THUNDERSTORM_ARGS and THOR_ARGS to pass any additional arguments to either binary
exec "$TARGET_DIR/tools/thunderstorm" \
    "--host" "${HOST:-0.0.0.0}" \
    "--port" "${PORT:-8000}" \
    "--queue-storage" "${QUEUE_STORAGE:-$TEMP_DIR/.persisted-uploads}" \
    "--queue-warn-size" "${QUEUE_WARN_SIZE:-50000}" \
    "--result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
    "--store-samples-score" "${STORE_SAMPLES_SCORE:-200}" \
    "--thor-location" "${THOR_LOCATION:-$TARGET_DIR}" \
    "--upload-dir" "$UPLOAD_DIR" \
    "--signature-update-interval" "${SIGNATURE_UPDATE_INTERVAL:-24}" \
    $THUNDERSTORM_ARGS \
    "--" \
    "--no-json" \
    $THOR_ARGS
