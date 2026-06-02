FROM alpine
LABEL maintainer="Marius Benthin <marius.benthin@nextron-systems.com>"

# install dependencies
RUN apk add --no-cache wget unzip

# specify environment variables
ENV TEMP_DIR="/tmp/thunderstorm"
ENV TARGET_DIR="/opt/nextron/thunderstorm"
ENV UPLOAD_DIR="$TEMP_DIR/uploads"

# create user, group and directories
RUN addgroup -g 1000 -S thunderstorm && \
    adduser -S -H -D -u 1000 -G thunderstorm -g "Thunderstorm User" thunderstorm && \
    mkdir -p \
        "$TEMP_DIR" \
        "$TEMP_DIR/.persisted-uploads" \
        "$TEMP_DIR/logs" \
        "$TEMP_DIR/vfs" \
        "$TARGET_DIR" \
        "$TARGET_DIR/config" \
        "$TARGET_DIR/plugins" \
        "$TARGET_DIR/signatures" \
        "$TARGET_DIR/custom-signatures" \
        "$UPLOAD_DIR" && \
    chown -R thunderstorm:thunderstorm "$TEMP_DIR" "$TARGET_DIR"

# copy unified entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER thunderstorm

ENTRYPOINT ["/entrypoint.sh"]