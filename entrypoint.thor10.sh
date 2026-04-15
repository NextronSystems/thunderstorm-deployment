#!/bin/sh

# download Thor if not already present
if [ ! -f "$TARGET_DIR/thor-util" ]; then
    if [ -z "$CONTRACT_TOKEN" ]; then
        echo "CONTRACT_TOKEN is required to download Thor!" >&2
        exit 1
    fi
    echo "Downloading Thor..." && \
    wget -q -O "$TEMP_DIR/thor.zip" "https://portal.nextron-systems.com/api/voucher/download/$CONTRACT_TOKEN/thor/linux" && \
        unzip -o -q "$TEMP_DIR/thor.zip" -d "$TARGET_DIR" && \
        rm "$TEMP_DIR/thor.zip"
fi

# update THOR signatures
"$TARGET_DIR/thor-util" update

# append optional TLS arguments to THUNDERSTORM_ARGS
[ -n "$TLS_CERT" ] && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --server-cert $TLS_CERT"
[ -n "$TLS_KEY" ]  && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --server-key $TLS_KEY"

# optionally write text log to volume; HTML and CSV are always disabled
if [ -n "$LOG_ENABLED" ]; then
    THOR_ARGS="-e $TEMP_DIR/logs --nohtml --nocsv $THOR_ARGS"
else
    THOR_ARGS="--nolog --nocsv $THOR_ARGS"
fi

# run Thunderstorm service
# use THUNDERSTORM_ARGS and THOR_ARGS to pass any additional arguments to either binary
exec "$TARGET_DIR/thor-linux-64" \
    "--thunderstorm" \
    "--server-host" "${HOST:-0.0.0.0}" \
    "--server-port" "8080" \
    "--server-upload-dir" "$UPLOAD_DIR" \
    "--server-result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
    "--server-store-samples" "${STORE_SAMPLES:-none}" \
    ${SYNC_ONLY_THREADS:+--sync-only-threads "$SYNC_ONLY_THREADS"} \
    ${PURE_YARA:+--pure-yara} \
    ${FORCE_MAX_FILE_SIZE:+--force-max-file-size} \
    $THUNDERSTORM_ARGS \
    $THOR_ARGS
