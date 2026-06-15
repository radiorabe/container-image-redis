FROM quay.io/sclorg/redis-6-c9s:20250108@sha256:b33dedfeb245199a03122505d35d9c75ae01d77ffe39e0950ed98b0d02ecdf64 AS source
FROM ghcr.io/radiorabe/ubi9-minimal:0.12.0@sha256:ddf3ac33c48b5005cc325732cb547279a926f29b3db9adcbd844f1cf94dcf831 AS app

ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/redis \
    HOME=/var/lib/redis \
    REDIS_VERSION=6 \
    REDIS_PREFIX=/usr \
    REDIS_CONF=/etc/redis/redis.conf

COPY --from=source /usr/share/container-scripts /usr/share/container-scripts
COPY --from=source /usr/libexec/container-setup /usr/libexec/container-setup
COPY --from=source /usr/bin/container-entrypoint /usr/bin/container-entrypoint
COPY --from=source /usr/bin/run-redis /usr/bin/run-redis
COPY --from=source /etc/redis /etc/redis

RUN    microdnf install -y \
         shadow-utils \
    && useradd -u 1001 -r -g 0 -s /sbin/nologin \
         -c "Redis User" redis \
    && microdnf install -y \
         gettext \
         policycoreutils \
         policycoreutils-restorecond \
         redis \
    && redis-server --version | grep -qe "^Redis server v=$REDIS_VERSION\." && echo "Found VERSION $REDIS_VERSION" \
    && mkdir -p /var/lib/redis/data \
    && chown -R redis:0 /var/lib/redis \
    && /usr/libexec/container-setup \
    && microdnf remove -y \
         libsemanage \
         policycoreutils \
         policycoreutils-restorecond \
         shadow-utils \
    && microdnf clean all \
    && [[ "$(id redis)" == "uid=1001(redis)"* ]]

EXPOSE 6379
USER 1001
VOLUME /var/lib/redis/data
ENTRYPOINT ["container-entrypoint"]
CMD ["run-redis"]
