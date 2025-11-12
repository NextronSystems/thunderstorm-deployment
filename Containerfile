FROM alpine
LABEL maintainer="Marius Benthin <marius.benthin@nextron-systems.com>"

# install dependencies
RUN apk add --no-cache wget unzip

# pass contract token via --build-args
ARG CONTRACT_TOKEN
RUN test -n "$CONTRACT_TOKEN" || (echo "CONTRACT_TOKEN is required!" && false)

# specify environment variables
ENV TEMP_DIR="/tmp/thunderstorm"
ENV TARGET_DIR="/opt/nextron/thunderstorm"
ENV UPLOAD_DIR="$TEMP_DIR/uploads"
ENV SIGNATURE_UPDATE_INTERVAL=24

# create directories
RUN mkdir -p "$TEMP_DIR" "$TARGET_DIR" "$UPLOAD_DIR"

# copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# create Thunderstorm user
RUN adduser -S -H -D -g "Thunderstorm User" thunderstorm
RUN chown -R thunderstorm "$TEMP_DIR" "$TARGET_DIR"
USER thunderstorm

# download and extract Thor
RUN wget -O "$TEMP_DIR/thor.zip" "https://portal.nextron-systems.com/api/voucher/download/$CONTRACT_TOKEN/thor/linux"
RUN unzip -o -q "$TEMP_DIR/thor.zip" -d "$TARGET_DIR"

# cleanup
RUN rm "$TEMP_DIR/thor.zip"

# copy custom THOR config
COPY custom-thor.yml "$TARGET_DIR/config/custom-thor.yml"

ENTRYPOINT ["/entrypoint.sh"]