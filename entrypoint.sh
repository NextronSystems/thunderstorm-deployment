#!/bin/sh

# download THOR if not already present
if [ ! -f "$TARGET_DIR/thor-util" ]; then
    if [ -z "$CONTRACT_TOKEN" ]; then
        echo "CONTRACT_TOKEN is required to download THOR!" >&2
        exit 0
    fi
    echo "Downloading THOR and issue license (if required) ..."
    # The Nextron cloud issues a license server-side and binds it to the host
    # identity sent in the X-Hostname header. Two optional environment variables
    # tune this (see README / docker-compose.yml):
    #   LICENSE_HOSTNAME - host identity for the issued license. Defaults to the
    #                      fixed value "thunderstorm-container" so re-downloads
    #                      reuse the same license slot instead of consuming new
    #                      contract quota on every fresh volume.
    #   LICENSE_COMMENT  - optional comment shown for the license in the portal.
    #
    # The optional X-Comment header is passed through a wrapper function so it
    # lives in the function's own positional parameters. This avoids "set --",
    # which would overwrite the entrypoint's "$@" (the excess arguments Docker
    # forwards from "docker run").
    download_thor() {
        wget "$@" \
            --header="X-Token: $CONTRACT_TOKEN" \
            --header="X-OS: linux" \
            --header="X-Arch: amd64" \
            --header="X-Type: server" \
            --header="X-Hostname: ${LICENSE_HOSTNAME:-thunderstorm-container}" \
            -O "$TEMP_DIR/thor.zip" \
            "https://cloud.nextron-systems.com/api/public/thor10"
    }
    if [ -n "$LICENSE_COMMENT" ]; then
        download_thor --header="X-Comment: $LICENSE_COMMENT"
    else
        download_thor
    fi && \
        unzip -o -q "$TEMP_DIR/thor.zip" -d "$TARGET_DIR" && \
        rm "$TEMP_DIR/thor.zip"
fi

# abort if THOR binary is not available
if [ ! -f "$TARGET_DIR/thor-linux-64" ]; then
    echo "THOR binary not found at $TARGET_DIR/thor-linux-64. Abort!"
    echo "Please verify that your CONTRACT_TOKEN is set and valid."
    exit 0
fi

# detect THOR channel using the "-dev" pre-release suffix in the manifest
# TODO: has to be adjusted once THOR 11 is in techpreview but does not carry the -dev suffix anymore
THOR_CHANNEL=stable
grep -qE '^version:.*-dev' "$TARGET_DIR/docs/manifest.yml" 2>/dev/null && THOR_CHANNEL=techpreview
echo "Detected THOR channel: $THOR_CHANNEL"

# upgrade to THOR channel "techpreview/dev" if requested and not already on it
if [ -n "$TECHPREVIEW" ] && [ "$THOR_CHANNEL" != "techpreview" ]; then
    "$TARGET_DIR/thor-util" upgrade --techpreview --dev
# downgrade to THOR channel "stable" if requested and not already on it
elif [ -z "$TECHPREVIEW" ] && [ "$THOR_CHANNEL" != "stable" ]; then
    "$TARGET_DIR/thor-util" upgrade
fi

# detect THOR major version from binary output, e.g. "THOR 11.0.0" -> "11"
THOR_VERSION=$("$TARGET_DIR/thor-linux-64" --version 2>&1 | awk '/^THOR / { split($2, v, "."); print v[1]; exit }')
if [ -z "$THOR_VERSION" ]; then
    echo "Failed to detect THOR major version from $TARGET_DIR/thor-linux-64 --version" >&2
    exit 0
fi
echo "Detected THOR major version: $THOR_VERSION"

# update THOR signatures on startup
"$TARGET_DIR/thor-util" update

# optionally download YARA Forge community signatures
if [ -n "$YARA_FORGE" ]; then
    _pkg_dir="$TARGET_DIR/custom-signatures/yara-forge/packages"
    if [ -e "$_pkg_dir/$YARA_FORGE" ]; then
        echo "YARA Forge ruleset '$YARA_FORGE' already installed, skipping download"
    else
        rm -rf "$_pkg_dir"
        echo "Downloading YARA Forge ruleset: $YARA_FORGE..."
        mkdir -p "$TARGET_DIR/custom-signatures/yara/yara-forge"
        "$TARGET_DIR/thor-util" yara-forge download --ruleset "$YARA_FORGE"
    fi
fi

# append optional TLS arguments to THUNDERSTORM_ARGS
if [ "$THOR_VERSION" = "11" ]; then
    [ -n "$TLS_CERT" ] && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --cert $TLS_CERT" || :
    [ -n "$TLS_KEY" ]  && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --key $TLS_KEY"   || :
else
    [ -n "$TLS_CERT" ] && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --server-cert $TLS_CERT" || :
    [ -n "$TLS_KEY" ]  && THUNDERSTORM_ARGS="$THUNDERSTORM_ARGS --server-key $TLS_KEY"   || :
fi

# --pure-yara and --force-max-file-size are THOR flags, append to THOR_ARGS
[ -n "$PURE_YARA" ] && THOR_ARGS="--pure-yara $THOR_ARGS" || :
[ -n "$FORCE_MAX_FILE_SIZE" ] && THOR_ARGS="--force-max-file-size $THOR_ARGS" || :

# optionally write log to volume; HTML and CSV are always disabled
if [ "$THOR_VERSION" = "11" ]; then
    if [ -n "$LOG_ENABLED" ]; then
        THOR_ARGS="--no-html --no-csv -e $TEMP_DIR/logs $THOR_ARGS"
    else
        THOR_ARGS="--no-json --no-csv $THOR_ARGS"
    fi
else
    if [ -n "$LOG_ENABLED" ]; then
        THOR_ARGS="-e $TEMP_DIR/logs --nohtml --nocsv $THOR_ARGS"
    else
        THOR_ARGS="--nolog --nocsv $THOR_ARGS"
    fi
fi

# run Thunderstorm service
# use THUNDERSTORM_ARGS and THOR_ARGS to pass any additional arguments to either binary
if [ "$THOR_VERSION" = "11" ]; then
    exec "$TARGET_DIR/tools/thunderstorm" \
        "--host" "${HOST:-0.0.0.0}" \
        "--port" "8080" \
        "--queue-storage" "$TEMP_DIR/.persisted-uploads" \
        "--queue-warn-size" "${QUEUE_WARN_SIZE:-50000}" \
        "--result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
        "--store-samples-score" "${STORE_SAMPLES_SCORE:-200}" \
        "--thor-location" "$TARGET_DIR" \
        "--upload-dir" "$UPLOAD_DIR" \
        ${VFS_ENABLED:+--vfs-dir "$TEMP_DIR/vfs"} \
        "--signature-update-interval" "${SIGNATURE_UPDATE_INTERVAL:-24}" \
        $THUNDERSTORM_ARGS \
        "--" \
        $THOR_ARGS
else
    exec "$TARGET_DIR/thor-linux-64" \
        "--thunderstorm" \
        "--server-host" "${HOST:-0.0.0.0}" \
        "--server-port" "8080" \
        "--server-upload-dir" "$UPLOAD_DIR" \
        "--server-result-cache-size" "${RESULT_CACHE_SIZE:-250000}" \
        "--server-store-samples" "${STORE_SAMPLES:-none}" \
        ${SYNC_ONLY_THREADS:+--sync-only-threads "$SYNC_ONLY_THREADS"} \
        $THUNDERSTORM_ARGS \
        $THOR_ARGS
fi
