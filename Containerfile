FROM alpine
LABEL maintainer="Marius Benthin <marius.benthin@nextron-systems.com>"

# install dependencies
RUN apk add --no-cache wget unzip

# specify environment variables
ENV TEMP_DIR="/tmp/thunderstorm"
ENV TARGET_DIR="/opt/nextron/thunderstorm"
ENV UPLOAD_DIR="$TEMP_DIR/uploads"

# create directories and user
RUN mkdir -p "$TEMP_DIR" "$TARGET_DIR" "$UPLOAD_DIR" && \
    adduser -S -H -D -g "Thunderstorm User" thunderstorm && \
    chown -R thunderstorm "$TEMP_DIR" "$TARGET_DIR"

# copy version-specific entrypoint script
ARG THOR_VERSION
RUN test -n "$THOR_VERSION" || (echo "THOR_VERSION is required!" && false)
COPY entrypoint.thor${THOR_VERSION}.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER thunderstorm

ENTRYPOINT ["/entrypoint.sh"]