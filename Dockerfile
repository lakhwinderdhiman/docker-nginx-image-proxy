FROM ubuntu:24.04 AS buildstep

# Set environment variables
ENV TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive

# Install required packages and nginx from Ubuntu repositories
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates lsb-release nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy nginx binaries and configurations to the final stage
FROM ubuntu:24.04

# Set environment variables
ENV TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive

# Copy nginx installation from the build stage
COPY --from=buildstep /etc/nginx /etc/nginx
COPY --from=buildstep /usr/sbin/nginx /usr/sbin/nginx

# Further configuration and installation of additional packages
RUN echo "\n\n* soft nofile 800000\n* hard nofile 800000\n\n" >> /etc/security/limits.conf && \
    apt-get update -y && apt-get install -y --no-install-recommends --no-install-suggests \
    curl gpg-agent nano libgd3 gettext-base unzip rsync cron apt-transport-https \
    software-properties-common ca-certificates libmaxminddb0 libmaxminddb-dev mmdb-bin \
    python3-pip git && \
    dpkg --configure -a && touch /var/log/cron.log && \
    pip3 install requests boto3 --break-system-packages && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# Additional configuration and custom scripts
ADD ./files/etc/ /etc/
ADD ./files/root/ /root/
ADD ./files/sbin/ /sbin/

# Run necessary scripts and set up logs
RUN bash /root/bin/dummycert.sh && \
    mkdir -p /app-start/etc && \
    mv /etc/nginx /app-start/etc/nginx && \
    rm -rf /etc/nginx && \
    ln -s /app/etc/nginx /etc/nginx && \
    mkdir -p /app-start/var/log && \
    mv /var/log/nginx /app-start/var/log/nginx && \
    rm -rf /var/log/nginx && \
    ln -s /app/var/log/nginx /var/log/nginx

# Expose necessary ports and define volumes
EXPOSE 80 443
VOLUME ["/app"]

CMD ["/sbin/my_init"]
