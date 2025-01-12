FROM ghcr.io/sdr-enthusiasts/docker-baseimage:mlatclient as downloader

# This downloader image has the rb24 apt repo added, and allows for downloading and extracting of rbfeeder binary deb package.
ARG TARGETPLATFORM TARGETOS TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039,SC2068
RUN set -x && \
    # install prereqs
    apt-get update && \
    apt-get install -y --no-install-recommends \
    binutils \
    gnupg \
    xz-utils \
    && \
    # add rb24 repo
    if [ "${TARGETARCH:0:3}" != "arm" ]; then \
        dpkg --add-architecture armhf; \
        RB24_PACKAGES=(rbfeeder:armhf); \
    else \
        RB24_PACKAGES=(rbfeeder); \
    fi && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
    bash -c "echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list" && \
    #
    # The lines below would allow the apt.rb24.com repo to be access insecurely. We were using this because their key had expired
    # However, as of 1-feb-2024, the repo was updated to contain again a valid key so this is no longer needed. Leaving it in as an archifact for future reference.
    # apt-get update -q --allow-insecure-repositories && \
    # apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests --allow-unauthenticated \
    #         "${RB24_PACKAGES[@]}"; \
    apt-get update -q && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
            "${RB24_PACKAGES[@]}"

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:wreadsb

# This is the final image

ENV BEASTHOST=readsb \
    BEASTPORT=30005 \
    UAT_RECEIVER_PORT=30979 \
    MLAT_SERVER=mlat1.rb24.com:40900 \
    RBFEEDER_LOG_FILE="/var/log/rbfeeder.log" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    STATS_INTERVAL_MINUTES=5 \
    VERBOSE_LOGGING=false \
    ENABLE_MLAT=true

ARG TARGETPLATFORM TARGETOS TARGETARCH

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039,SC2068,SC2010
RUN \
    --mount=type=bind,from=downloader,source=/,target=/downloader \
    --mount=type=bind,source=./,target=/app/ \
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # required for adding rb24 repo
    # TEMP_PACKAGES+=(gnupg) && \
    # required to run rbfeeder
    if [ "${TARGETARCH:0:3}" != "arm" ]; then \
        dpkg --add-architecture armhf; \
        KEPT_PACKAGES+=(libc6:armhf) && \
        KEPT_PACKAGES+=(libcurl4:armhf) && \
        KEPT_PACKAGES+=(libglib2.0-0:armhf) && \
        KEPT_PACKAGES+=(libjansson4:armhf) && \
        KEPT_PACKAGES+=(libprotobuf-c1:armhf) && \
        KEPT_PACKAGES+=(librtlsdr0:armhf) && \
        KEPT_PACKAGES+=(qemu-user-static); \
    else \
        KEPT_PACKAGES+=(libc6) && \
        KEPT_PACKAGES+=(libcurl4) && \
        KEPT_PACKAGES+=(libglib2.0-0) && \
        KEPT_PACKAGES+=(libjansson4) && \
        KEPT_PACKAGES+=(libprotobuf-c1) && \
        KEPT_PACKAGES+=(librtlsdr0); \
    fi && \
    KEPT_PACKAGES+=(netbase) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" \
    && \
    # download files from the downloader image that is now mounted at /downloader
    mkdir -p /usr/share/doc/rbfeeder && \
    cp -f /downloader/usr/bin/rbfeeder /usr/bin/rbfeeder_arm && \
    cp -f /downloader/usr/bin/dump1090-rb /usr/bin/dump1090-rb && \
    cp -f /downloader/usr/share/doc/rbfeeder/* /usr/share/doc/rbfeeder/ && \
    cp -f /app/rootfs/usr/bin/rbfeeder_wrapper.sh /usr/bin/rbfeeder_wrapper.sh && \
    # test rbfeeder & get version
    /usr/bin/rbfeeder --version && \
    RBFEEDER_VERSION=$(/usr/bin/rbfeeder --no-start --version | cut -d " " -f 2,4 | tr -d ")" | tr " " "-") && \
    echo "$RBFEEDER_VERSION" > /CONTAINER_VERSION && \
    # delete unnecessary qemu binaries to save lots of space
    { find /usr/bin -regex '/usr/bin/qemu-.*-static'  | grep -v qemu-arm-static | xargs rm -vf {} || true; } && \
    # clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# Add everything else to the container
COPY rootfs/ /

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /healthcheck.sh
