FROM ubuntu:24.04 AS buildstep

# Set environment variables

ENV TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive \
    NGINX_DEVEL_KIT_VERSION=0.3.3 NGINX_SET_MISC_MODULE_VERSION=0.33 \
    NGINX_VERSION=1.24.0

# Install required packages and nginx
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates lsb-release && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    echo "deb https://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list && \
    apt-get update -y && \
    apt-get install -y nginx=${NGINX_VERSION} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy nginx binary and configuration to final image
FROM ubuntu:24.04

# Set environment variables
ENV TERM=xterm container=docker DEBIAN_FRONTEND=noninteractive

# Copy the nginx package from the buildstep stage
COPY --from=buildstep /etc/nginx /etc/nginx
COPY --from=buildstep /usr/sbin/nginx /usr/sbin/nginx

# Additional configurations and package installations
RUN echo "\n\n* soft nofile 800000\n* hard nofile 800000\n\n" >> /etc/security/limits.conf && \
    apt-get update -y && apt-get upgrade -y --no-install-recommends --no-install-suggests && \
    apt-get install -y --no-install-recommends --no-install-suggests curl gpg-agent nano \
       libgd3 gettext-base unzip rsync cron apt-transport-https software-properties-common \
       ca-certificates libmaxminddb0 libmaxminddb-dev mmdb-bin python3-pip git && \
    dpkg --configure -a && touch /var/log/cron.log && \
    pip3 install requests boto3 --break-system-packages && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# Add custom files and configuration
ADD ./files/etc/ /etc/
ADD ./files/root/ /root/
ADD ./files/sbin/ /sbin/

# Run necessary scripts and create symlinks for logs
RUN bash /root/bin/dummycert.sh && \
    mkdir -p /app-start/etc && \
    mv /etc/nginx /app-start/etc/nginx && \
    rm -rf /etc/nginx && \
    ln -s /app/etc/nginx /etc/nginx && \
    mkdir -p /app-start/var/log && \
    mv /var/log/nginx /app-start/var/log/nginx && \
    rm -rf /var/log/nginx && \
    ln -s /app/var/log/nginx /var/log/nginx

# Expose ports and define volumes
EXPOSE 80 443
VOLUME ["/app"]

CMD ["/sbin/my_init"]
